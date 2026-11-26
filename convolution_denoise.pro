FUNCTION get_kernel, filterIndex, scale

  ; 用权重总和归一化，保持均匀区域的亮度
  IF filterIndex EQ 0 THEN BEGIN
    scale = 9.0
    RETURN, FLTARR(3, 3) + 1.0
  ENDIF

  scale = 16.0
  RETURN, [[1.0, 2.0, 1.0], [2.0, 4.0, 2.0], [1.0, 2.0, 1.0]]

END


PRO denoise_show_gray, drawID, image

  COMMON convolution_data, grayImage, resultImage

  ; 左右预览共用输入波段的灰度范围
  low = MIN(grayImage, MAX=high)
  preview = image
  IF high GT low THEN preview = BYTSCL(image, MIN=low, MAX=high)

  preview = CONGRID(preview, 500, 400, /INTERP)

  WIDGET_CONTROL, drawID, GET_VALUE=winID
  WSET, winID
  TV, preview, /ORDER

END


PRO convolution_denoise_event, event

  COMMON convolution_data, grayImage, resultImage

  WIDGET_CONTROL, event.top, GET_UVALUE=state

  IF event.id EQ state.openBtn THEN BEGIN

    file = DIALOG_PICKFILE()
    IF file EQ '' THEN RETURN

    image = READ_IMAGE(file)
    dim = SIZE(image, /N_DIMENSIONS)

    ; 二维图直接使用，三维影像按[波段数, 宽, 高]取第1波段
    CASE dim OF
      2: inputBand = image
      3: BEGIN
        dims = SIZE(image, /DIMENSIONS)
        inputBand = REFORM(image[0, *, *], dims[1], dims[2])
      END
      ELSE: BEGIN
        WIDGET_CONTROL, state.statusLabel, SET_VALUE='Unsupported image dimensions.'
        RETURN
      END
    ENDCASE

    dims = SIZE(inputBand, /DIMENSIONS)
    IF (dims[0] LT 3) OR (dims[1] LT 3) THEN BEGIN
      WIDGET_CONTROL, state.statusLabel, SET_VALUE='Image must be at least 3 x 3 pixels.'
      RETURN
    ENDIF

    typeName = SIZE(inputBand, /TNAME)
    grayImage = inputBand
    IF typeName NE 'BYTE' THEN grayImage = BYTSCL(inputBand)
    resultImage = 0

    info = 'Width: ' + STRTRIM(dims[0], 2) + '  Height: ' + STRTRIM(dims[1], 2)
    info = info + '  Type: ' + typeName
    WIDGET_CONTROL, state.infoLabel, SET_VALUE=info
    WIDGET_CONTROL, state.statusLabel, SET_VALUE='Image opened.'

    denoise_show_gray, state.originalDraw, grayImage

    ; 换图后清空旧结果
    WIDGET_CONTROL, state.resultDraw, GET_VALUE=resultWin
    WSET, resultWin
    ERASE
    RETURN

  ENDIF

  IF event.id EQ state.processBtn THEN BEGIN

    IF SIZE(grayImage, /N_DIMENSIONS) NE 2 THEN BEGIN
      WIDGET_CONTROL, state.statusLabel, SET_VALUE='Please open an image first.'
      RETURN
    ENDIF

    filterIndex = WIDGET_INFO(state.filterList, /DROPLIST_SELECT)
    kernel = get_kernel(filterIndex, scale)

    ; 浮点卷积，四舍五入后转回8位灰度
    filtered = CONVOL(FLOAT(grayImage), kernel, scale, /EDGE_TRUNCATE)
    resultImage = BYTE(ROUND(filtered))

    denoise_show_gray, state.resultDraw, resultImage

    status = 'Mean filter completed.'
    IF filterIndex EQ 1 THEN status = 'Gaussian filter completed.'
    WIDGET_CONTROL, state.statusLabel, SET_VALUE=status
    RETURN

  ENDIF

  IF event.id EQ state.saveBtn THEN BEGIN

    IF SIZE(resultImage, /N_DIMENSIONS) NE 2 THEN BEGIN
      WIDGET_CONTROL, state.statusLabel, SET_VALUE='No result to save.'
      RETURN
    ENDIF

    saveFile = DIALOG_PICKFILE(/WRITE, FILTER='*.png')
    IF saveFile EQ '' THEN RETURN

    nameLength = STRLEN(saveFile)
    IF nameLength LT 4 THEN BEGIN
      saveFile = saveFile + '.png'
    ENDIF ELSE BEGIN
      suffix = STRMID(STRLOWCASE(saveFile), nameLength - 4, 4)
      IF suffix NE '.png' THEN saveFile = saveFile + '.png'
    ENDELSE

    ; 调整行顺序，使PNG方向与界面一致
    WRITE_PNG, saveFile, REVERSE(resultImage, 2)
    WIDGET_CONTROL, state.statusLabel, SET_VALUE='Result saved: ' + saveFile

  ENDIF

END


PRO convolution_denoise

  COMMON convolution_data, grayImage, resultImage

  grayImage = 0
  resultImage = 0

  base = WIDGET_BASE(TITLE='Remote Sensing Convolution Denoising Tool', /COLUMN)
  buttonRow = WIDGET_BASE(base, /ROW)

  openBtn = WIDGET_BUTTON(buttonRow, VALUE='Open Image')
  filterList = WIDGET_DROPLIST(buttonRow, VALUE=['Mean 3x3', 'Gaussian 3x3'])
  processBtn = WIDGET_BUTTON(buttonRow, VALUE='Convolution')
  saveBtn = WIDGET_BUTTON(buttonRow, VALUE='Save Result')

  infoLabel = WIDGET_LABEL(base, VALUE='No image opened', XSIZE=1000)
  statusLabel = WIDGET_LABEL(base, VALUE='Ready', XSIZE=1000)

  displayRow = WIDGET_BASE(base, /ROW)

  originalColumn = WIDGET_BASE(displayRow, /COLUMN)
  originalLabel = WIDGET_LABEL(originalColumn, VALUE='Original Image')
  originalDraw = WIDGET_DRAW(originalColumn, XSIZE=500, YSIZE=400, RETAIN=2)

  resultColumn = WIDGET_BASE(displayRow, /COLUMN)
  resultLabel = WIDGET_LABEL(resultColumn, VALUE='Denoising Result')
  resultDraw = WIDGET_DRAW(resultColumn, XSIZE=500, YSIZE=400, RETAIN=2)

  state = {openBtn:openBtn, filterList:filterList, processBtn:processBtn, saveBtn:saveBtn, infoLabel:infoLabel, statusLabel:statusLabel, originalDraw:originalDraw, resultDraw:resultDraw}

  WIDGET_CONTROL, base, SET_UVALUE=state
  WIDGET_CONTROL, base, /REALIZE
  XMANAGER, 'convolution_denoise', base, EVENT_HANDLER='convolution_denoise_event'

END
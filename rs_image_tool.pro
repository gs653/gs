; 在指定绘图区显示图像
PRO show_image, drawID, image

  WIDGET_CONTROL, drawID, GET_VALUE=winID
  WSET, winID

  dim = SIZE(image, /N_DIMENSIONS)

  ; 单波段图像
  IF dim EQ 2 THEN BEGIN
    displayImage = CONGRID(image, 500, 400, /INTERP)
    TV, displayImage, /ORDER
  ENDIF

  ; 多波段或RGB图像
  IF dim EQ 3 THEN BEGIN

    dims = SIZE(image, /DIMENSIONS)

    IF dims[0] EQ 3 THEN BEGIN
      rgbImage = image
    ENDIF ELSE BEGIN
      rgbImage = BYTARR(3, dims[1], dims[2])
      rgbImage[0, *, *] = BYTSCL(REFORM(image[0, *, *]))
      rgbImage[1, *, *] = BYTSCL(REFORM(image[1, *, *]))
      rgbImage[2, *, *] = BYTSCL(REFORM(image[2, *, *]))
    ENDELSE

    displayImage = CONGRID(rgbImage, 3, 500, 400, /INTERP)
    TV, displayImage, TRUE=1, /ORDER

  ENDIF

END


; 界面事件响应
PRO rs_image_tool_event, event

  COMMON image_data, img, result

  WIDGET_CONTROL, event.top, GET_UVALUE=state


  ; 打开TIFF影像
  IF event.id EQ state.openBtn THEN BEGIN

    file = DIALOG_PICKFILE(FILTER='*.tif')
    IF file EQ '' THEN RETURN

    img = READ_TIFF(file)
    result = BYTSCL(img)

    dim = SIZE(img, /N_DIMENSIONS)
    dims = SIZE(img, /DIMENSIONS)
    typeName = SIZE(img, /TNAME)

    IF dim EQ 2 THEN BEGIN
      width = dims[0]
      height = dims[1]
      bandCount = 1
    ENDIF ELSE BEGIN
      width = dims[1]
      height = dims[2]
      bandCount = dims[0]
    ENDELSE

    info = 'Width: ' + STRTRIM(width, 2) + '  Height: ' + STRTRIM(height, 2) + '  Bands: ' + STRTRIM(bandCount, 2) + '  Type: ' + typeName

    WIDGET_CONTROL, state.infoLabel, SET_VALUE=info

    ; 左侧显示原始影像
    show_image, state.originalDraw, result

    ; 清空右侧处理结果
    WIDGET_CONTROL, state.resultDraw, GET_VALUE=resultWin
    WSET, resultWin
    ERASE

  ENDIF


  ; 显示指定波段
  IF event.id EQ state.bandBtn THEN BEGIN

    IF SIZE(img, /N_DIMENSIONS) EQ 0 THEN BEGIN
      WIDGET_CONTROL, state.infoLabel, SET_VALUE='Please open an image first.'
      RETURN
    ENDIF

    WIDGET_CONTROL, state.bandText, GET_VALUE=value
    bandNo = FIX(value[0]) - 1

    dim = SIZE(img, /N_DIMENSIONS)
    dims = SIZE(img, /DIMENSIONS)

    IF dim EQ 2 THEN BEGIN

      IF bandNo NE 0 THEN BEGIN
        WIDGET_CONTROL, state.infoLabel, SET_VALUE='This image has only one band.'
        RETURN
      ENDIF

      result = BYTSCL(img)

    ENDIF ELSE BEGIN

      bandCount = dims[0]

      IF (bandNo LT 0) OR (bandNo GE bandCount) THEN BEGIN
        message = 'Band number must be between 1 and ' + STRTRIM(bandCount, 2)
        WIDGET_CONTROL, state.infoLabel, SET_VALUE=message
        RETURN
      ENDIF

      band = REFORM(img[bandNo, *, *])
      result = BYTSCL(band)

    ENDELSE

    WIDGET_CONTROL, state.infoLabel, SET_VALUE='Band displayed.'

    ; 右侧显示单波段结果
    show_image, state.resultDraw, result

  ENDIF


  ; 假彩色合成
  IF event.id EQ state.colorBtn THEN BEGIN

    IF SIZE(img, /N_DIMENSIONS) NE 3 THEN BEGIN
      WIDGET_CONTROL, state.infoLabel, SET_VALUE='False color requires a multiband image.'
      RETURN
    ENDIF

    WIDGET_CONTROL, state.rText, GET_VALUE=rValue
    WIDGET_CONTROL, state.gText, GET_VALUE=gValue
    WIDGET_CONTROL, state.bText, GET_VALUE=bValue

    rNo = FIX(rValue[0]) - 1
    gNo = FIX(gValue[0]) - 1
    bNo = FIX(bValue[0]) - 1

    dims = SIZE(img, /DIMENSIONS)
    bandCount = dims[0]

    IF (rNo LT 0) OR (rNo GE bandCount) OR (gNo LT 0) OR (gNo GE bandCount) OR (bNo LT 0) OR (bNo GE bandCount) THEN BEGIN
      message = 'RGB bands must be between 1 and ' + STRTRIM(bandCount, 2)
      WIDGET_CONTROL, state.infoLabel, SET_VALUE=message
      RETURN
    ENDIF

    width = dims[1]
    height = dims[2]

    result = BYTARR(3, width, height)
    result[0, *, *] = BYTSCL(REFORM(img[rNo, *, *]))
    result[1, *, *] = BYTSCL(REFORM(img[gNo, *, *]))
    result[2, *, *] = BYTSCL(REFORM(img[bNo, *, *]))

    WIDGET_CONTROL, state.infoLabel, SET_VALUE='False color completed.'

    ; 右侧显示假彩色结果
    show_image, state.resultDraw, result

  ENDIF


  ; 计算NDVI
  IF event.id EQ state.ndviBtn THEN BEGIN

    IF SIZE(img, /N_DIMENSIONS) NE 3 THEN BEGIN
      WIDGET_CONTROL, state.infoLabel, SET_VALUE='NDVI requires a multiband image.'
      RETURN
    ENDIF

    WIDGET_CONTROL, state.nirText, GET_VALUE=nirValue
    WIDGET_CONTROL, state.redText, GET_VALUE=redValue

    nirNo = FIX(nirValue[0]) - 1
    redNo = FIX(redValue[0]) - 1

    dims = SIZE(img, /DIMENSIONS)
    bandCount = dims[0]

    IF (nirNo LT 0) OR (nirNo GE bandCount) OR (redNo LT 0) OR (redNo GE bandCount) THEN BEGIN
      message = 'NDVI bands must be between 1 and ' + STRTRIM(bandCount, 2)
      WIDGET_CONTROL, state.infoLabel, SET_VALUE=message
      RETURN
    ENDIF

    nirBand = FLOAT(REFORM(img[nirNo, *, *]))
    redBand = FLOAT(REFORM(img[redNo, *, *]))

    denominator = nirBand + redBand
    ndvi = FLTARR(dims[1], dims[2])

    ; 避免分母为0
    valid = WHERE(denominator NE 0, count)

    IF count GT 0 THEN ndvi[valid] = (nirBand[valid] - redBand[valid]) / denominator[valid]

    ; 将NDVI转换为灰度图
    result = BYTSCL(ndvi, MIN=-1.0, MAX=1.0)

    WIDGET_CONTROL, state.infoLabel, SET_VALUE='NDVI completed.'

    ; 右侧显示NDVI结果
    show_image, state.resultDraw, result

  ENDIF


  ; 保存当前处理结果
  IF event.id EQ state.saveBtn THEN BEGIN

    IF SIZE(result, /N_DIMENSIONS) EQ 0 THEN BEGIN
      WIDGET_CONTROL, state.infoLabel, SET_VALUE='No result to save.'
      RETURN
    ENDIF

    saveFile = DIALOG_PICKFILE(/WRITE, FILTER='*.png')
    IF saveFile EQ '' THEN RETURN

    lowerName = STRLOWCASE(saveFile)
    nameLength = STRLEN(lowerName)

    ; 自动添加PNG扩展名
    IF nameLength LT 4 THEN BEGIN
      saveFile = saveFile + '.png'
    ENDIF ELSE BEGIN
      IF STRMID(lowerName, nameLength - 4, 4) NE '.png' THEN saveFile = saveFile + '.png'
    ENDELSE

    ; 保存前进行上下翻转，使保存方向与界面一致
    resultDim = SIZE(result, /N_DIMENSIONS)
    resultSize = SIZE(result, /DIMENSIONS)

    IF resultDim EQ 2 THEN BEGIN
      saveImage = result[*, resultSize[1] - 1 - INDGEN(resultSize[1])]
    ENDIF

    IF resultDim EQ 3 THEN BEGIN
      saveImage = result[*, *, resultSize[2] - 1 - INDGEN(resultSize[2])]
    ENDIF

    WRITE_PNG, saveFile, saveImage
    WIDGET_CONTROL, state.infoLabel, SET_VALUE='Result saved: ' + saveFile

  ENDIF

END


; 主程序
PRO rs_image_tool

  COMMON image_data, img, result

  img = 0
  result = 0

  ; 创建主界面
  base = WIDGET_BASE(TITLE='Remote Sensing Image Tool', /COLUMN)

  openBtn = WIDGET_BUTTON(base, VALUE='Open TIFF', XSIZE=1000)
  infoLabel = WIDGET_LABEL(base, VALUE='No image opened', XSIZE=1000)

  ; 单波段显示控件
  bandRow = WIDGET_BASE(base, /ROW)
  bandLabel = WIDGET_LABEL(bandRow, VALUE='Band:')
  bandText = WIDGET_TEXT(bandRow, VALUE='1', /EDITABLE, XSIZE=5)
  bandBtn = WIDGET_BUTTON(bandRow, VALUE='Display Band')

  ; 假彩色合成控件
  colorRow = WIDGET_BASE(base, /ROW)
  rLabel = WIDGET_LABEL(colorRow, VALUE='R:')
  rText = WIDGET_TEXT(colorRow, VALUE='3', /EDITABLE, XSIZE=4)
  gLabel = WIDGET_LABEL(colorRow, VALUE='G:')
  gText = WIDGET_TEXT(colorRow, VALUE='2', /EDITABLE, XSIZE=4)
  bLabel = WIDGET_LABEL(colorRow, VALUE='B:')
  bText = WIDGET_TEXT(colorRow, VALUE='1', /EDITABLE, XSIZE=4)
  colorBtn = WIDGET_BUTTON(colorRow, VALUE='False Color')

  ; NDVI和保存控件
  ndviRow = WIDGET_BASE(base, /ROW)
  nirLabel = WIDGET_LABEL(ndviRow, VALUE='NIR:')
  nirText = WIDGET_TEXT(ndviRow, VALUE='1', /EDITABLE, XSIZE=4)
  redLabel = WIDGET_LABEL(ndviRow, VALUE='Red:')
  redText = WIDGET_TEXT(ndviRow, VALUE='3', /EDITABLE, XSIZE=4)
  ndviBtn = WIDGET_BUTTON(ndviRow, VALUE='NDVI')
  saveBtn = WIDGET_BUTTON(ndviRow, VALUE='Save Result')

  ; 左右两个图像显示窗口
  displayRow = WIDGET_BASE(base, /ROW)

  originalColumn = WIDGET_BASE(displayRow, /COLUMN)
  originalLabel = WIDGET_LABEL(originalColumn, VALUE='Original Image')
  originalDraw = WIDGET_DRAW(originalColumn, XSIZE=500, YSIZE=400, RETAIN=2)

  resultColumn = WIDGET_BASE(displayRow, /COLUMN)
  resultLabel = WIDGET_LABEL(resultColumn, VALUE='Processing Result')
  resultDraw = WIDGET_DRAW(resultColumn, XSIZE=500, YSIZE=400, RETAIN=2)

  ; 保存控件编号
  state = {openBtn:openBtn, infoLabel:infoLabel, bandText:bandText, bandBtn:bandBtn, rText:rText, gText:gText, bText:bText, colorBtn:colorBtn, nirText:nirText, redText:redText, ndviBtn:ndviBtn, saveBtn:saveBtn, originalDraw:originalDraw, resultDraw:resultDraw}

  WIDGET_CONTROL, base, SET_UVALUE=state
  WIDGET_CONTROL, base, /REALIZE

  XMANAGER, 'rs_image_tool', base, EVENT_HANDLER='rs_image_tool_event'

END
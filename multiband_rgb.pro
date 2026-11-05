; 函数1：选择图像文件，返回文件路径
FUNCTION pickFile

  file = DIALOG_PICKFILE()

  RETURN, file

END


; 函数2：根据文件路径读取图像，返回图像数组
FUNCTION readImg, file

  img = READ_IMAGE(file)

  RETURN, img

END


; 函数3：判断图像维度和波段编号，返回指定波段
FUNCTION getBand, img, bandNo

  ; 获取图像维度数量
  dim = SIZE(img, /N_DIMENSIONS)

  ; 获取每一维的大小
  dims = SIZE(img, /DIMENSIONS)

  ; 二维图像为单波段灰度图
  IF dim EQ 2 THEN BEGIN

    ; 二维图像只有第1波段，下标为0
    IF bandNo NE 0 THEN BEGIN
      PRINT, 'This image has only one band.'
      PRINT, 'Please use bandNo = 0.'
      RETURN, 0
    ENDIF

    RETURN, img

  ENDIF


  ; 三维图像格式为：[波段数, 宽, 高]
  IF dim EQ 3 THEN BEGIN

    ; 第一维表示波段数
    bandCount = dims[0]

    PRINT, 'Band count: ', bandCount

    ; 判断波段编号是否越界
    IF (bandNo LT 0) OR (bandNo GE bandCount) THEN BEGIN
      PRINT, 'Invalid band number.'
      PRINT, 'Valid range: 0 to ', bandCount - 1
      RETURN, 0
    ENDIF

    ; 提取指定波段，并转换成二维数组
    band = REFORM(img[bandNo, *, *])

    RETURN, band

  ENDIF


  ; 不是二维或三维图像
  PRINT, 'Unsupported image dimensions.'

  RETURN, 0

END


; 主程序
PRO multiband_rgb

  ; 调用函数1：选择图像文件
  file = pickFile()

  ; 没有选择文件则结束程序
  IF file EQ '' THEN RETURN


  ; 调用函数2：读取图像
  img = readImg(file)

  ; 查看图像的数据类型和维度
  HELP, img


  ; 选择要提取的波段
  ; 0表示第1波段，1表示第2波段，2表示第3波段
  bandNo = 0

  ; 调用函数3：取得指定波段
  band = getBand(img, bandNo)


  ; 判断是否成功得到二维波段
  IF SIZE(band, /N_DIMENSIONS) NE 2 THEN BEGIN
    PRINT, 'Failed to get image band.'
    RETURN
  ENDIF

  ; 查看取得的波段
  HELP, band


  ; 将波段灰度值拉伸到0～255
  bandShow = BYTSCL(band)


  ; 获取波段图像的宽和高
  dims = SIZE(bandShow, /DIMENSIONS)
  width = dims[0]
  height = dims[1]


  ; 创建窗口并显示波段
  WINDOW, 0, XSIZE=width, YSIZE=height
  TV, bandShow, /ORDER


  ; 保存显示结果
  WRITE_PNG, 'band.png', bandShow

END
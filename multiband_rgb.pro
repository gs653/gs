PRO multiband_rgb

  file = DIALOG_PICKFILE()
  IF file EQ '' THEN RETURN

  img = READ_TIFF(file)
  HELP, img

  ; 提取三个波段
  R = img[0, *, *]
  G = img[1, *, *]
  B = img[2, *, *]

  ; 拉伸到0～255
  R = BYTSCL(R)
  G = BYTSCL(G)
  B = BYTSCL(B)

  ; 获取宽、高
  dims = SIZE(img, /DIMENSIONS)
  width = dims[1]
  height = dims[2]

  ; 组成RGB图像
  rgb = BYTARR(3, width, height)
  rgb[0, *, *] = R
  rgb[1, *, *] = G
  rgb[2, *, *] = B

  ; 检查合成后的维度
  HELP, rgb

  ; 显示
  WINDOW, 0, XSIZE=width, YSIZE=height
  TV, rgb, TRUE=1

  ; 保存
  WRITE_PNG, 'rgb.png', rgb
  ; 假彩色合成：交换红、蓝通道
  rgb_false = BYTARR(3, width, height)
  rgb_false[0, *, *] = B
  rgb_false[1, *, *] = G
  rgb_false[2, *, *] = R

  ; 在新窗口显示假彩色结果
  WINDOW, 1, XSIZE=width, YSIZE=height
  TV, rgb_false, TRUE=1

  ; 保存假彩色结果
  WRITE_PNG, 'rgb_false.png', rgb_false
END
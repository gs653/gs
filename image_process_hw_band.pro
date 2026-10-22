pro image_process_hw_band

  sFilePath = dialog_pickfile(title='请选择一张 TIFF 遥感影像')
  if (sFilePath eq '') then return

  imgTIF = read_tiff(sFilePath)
  print, '图像信息：'
  Help, imgTIF


  sz = size(imgTIF, /DIMENSIONS)
  print, '当前图像总共有 ', sz[0], ' 个波段'


  band1 = imgTIF[0, *, *] ; 取波段 1
  band2 = imgTIF[1, *, *] ; 取波段 2
  band3 = imgTIF[2, *, *] ; 取波段 3


  WINDOW, 0, title='Band 1 (TVSCL)'
  TVSCL, band1


  band1_byte = BYTSCL(band1)

  outFileName = 'C:\Users\gaosh\Desktop\gs-idl\band1_result.png'
  write_png, outFileName, band1_byte
  print, 'Band 1 已提取并保存为: ', outFileName

  band2_byte = BYTSCL(band2)
  write_png, 'C:\Users\gaosh\Desktop\gs-idl\band2_result.png', band2_byte
  print, 'Band 2 已提取并保存为: band2_result.png'
end
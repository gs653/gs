pro gameImgOps
  ;1.get file path
  sImgPath=dialog_pickfile()
  
  ;2.open the image
  imgP=Read_image(sImgPath)
  help,imgp
 
  ;3.show the image
  window,0
  tv,imgP,true=1
  ;tv,imgP
  
END
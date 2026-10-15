;高尚 202406030106
;this is my test program for file operation.
pro newFileGame
  file = dialog_pickfile()
  print,file
  numLines = file_lines(file)
  print, 'numbers of lines = ', numLines

  xDataArr = dblarr(numLines)
  yDataArr = dblarr(numLines)
  zDataArr = dblarr(numLines)

  openr, funR, file, /get_lun
  strLine = ''
  index = 0

  while (~eof(funR)) do begin
    readf, funR, strLine
    strLine = strtrim(strLine,2)
    if(strlen(strLine) le 0) then continue ;跳过空行
    
    ;把 ,, 替换成 ,0, 填充中间空缺字段
    strLine = strreplace(strLine, ',,', ',0,')
    ;全部逗号替换为空格，变成空格分隔文本
    strLine = strreplace(strLine, ',', ' ')
    
    ;reads直接解析5个数值：id dummy x y z
    reads, strLine, idv, dummy, xv, yv, zv, /nolog
    
    xDataArr[index] = xv
    yDataArr[index] = yv
    zDataArr[index] = zv
    index = index + 1
  endwhile
  free_lun, funR

  print,'有效行数 index = ',index
  if(index le 0)then begin
    print,'没有读到任何有效数据！'
    return
  endif

  xDataArr = xDataArr[0:index - 1]
  yDataArr = yDataArr[0:index - 1]
  zDataArr = zDataArr[0:index - 1]

  device, decomposed=1

  ;第一张：白底
  window,0,xsize=600,ysize=500,xpos=50,ypos=50,title='White Background Scatter'
  plot, xDataArr, zDataArr, /nodata, title='White Background Scatter', background='FFFFFF'x
  oplot, xDataArr, zDataArr, psym=4, color='FF0000'x

  ;第二张：黑底
  window,1,xsize=600,ysize=500,xpos=700,ypos=50,title='Black Background Scatter'
  plot, xDataArr, zDataArr, /nodata, title='Black Background Scatter', background='000000'x, color='FFFFFF'x
  oplot, xDataArr, zDataArr, psym=4,

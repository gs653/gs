;高尚 202406030106
;this is my test program for file operation.
pro newFileGame
;==================== 【第一类：变量定义】====================
  file = ''
  numLines = 0L
  xDataArr = dblarr(1000)
  yDataArr = dblarr(1000)
  zDataArr = dblarr(1000)
  strLine = ''
  index = 0L
  nPart = 0L
  idv=0.0d & dummy=0.0d & xv=0.0d & yv=0.0d & zv=0.0d

;==================== 【第二类：文件读取】====================
  file = dialog_pickfile(filter='*.dat',title='选择Dgx.dat数据文件')
  if (file eq '') then begin
    print,'没有选择文件，退出程序'
    return
  endif
  print,'选中文件：',file

  numLines = file_lines(file)
  print,'总行数：',numLines

  openr, funR, file, /get_lun
  index = 0

  while (~eof(funR)) do begin
    readf, funR, strLine
    strLine = strtrim(strLine,2)
    if (strlen(strLine) le 0) then continue

    parts = strsplit(strLine, ',', /extract, /preserve_null)
    nPart = n_elements(parts)

    if (nPart ge 1) then idv = double(parts[0])
    if (nPart ge 2) then dummy = double(parts[1])
    if (nPart ge 3) then xv = double(parts[2])
    if (nPart ge 4) then yv = double(parts[3])
    if (nPart ge 5) then zv = double(parts[4])

    xDataArr[index] = xv
    yDataArr[index] = yv
    zDataArr[index] = zv
    index = index + 1
  endwhile
  free_lun,funR

;==================== 【第三类：数据处理】====================
  print,'有效数据行数：',index
  if (index le 0) then begin
    print,'读取数据失败'
    return
  endif
  xDataArr = xDataArr[0:index-1]
  zDataArr = zDataArr[0:index-1]

  ; 计算极值，打印出来看
  xmin = min(xDataArr)
  xmax = max(xDataArr)
  zmin = min(zDataArr)
  zmax = max(zDataArr)
  print,'xmin,xmax: ',xmin,xmax
  print,'zmin,zmax: ',zmin,zmax

;==================== 【第四类：绘图输出】====================
  device,decomposed=0
  window,0,xsize=700,ysize=500,xpos=50,ypos=50,title='Data Scatter Plot'
  ;重点！！xrange和yrange使用方括号[]，不是()
  plot,xDataArr,zDataArr,title='Data Scatter Plot',background=255,color=0,/nodata,$
    xtitle='X Axis',ytitle='Y Axis',xstyle=1,ystyle=1,$
    xrange=[xmin,xmax],yrange=[zmin,zmax]
  oplot,xDataArr,zDataArr,psym=4,symsize=0.8,color=0

  print,'====图像绘制完成！图像窗口已经打开，去桌面查看！===='
end

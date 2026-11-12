PRO gui_event, event

  WIDGET_CONTROL, event.top, GET_UVALUE=drawID

  file = DIALOG_PICKFILE()
  IF file EQ '' THEN RETURN

  img = READ_IMAGE(file)
  WIDGET_CONTROL, drawID, GET_VALUE=winID
  WSET, winID
  ; 判断是二维灰度还是三维彩色图
  dim = SIZE(img, /N_DIMENSIONS)

  IF dim EQ 2 THEN TVSCL, img
  IF dim EQ 3 THEN TV, BYTSCL(img), TRUE=1

END


PRO gui_demo

  ; 创建界面
  base = WIDGET_BASE(TITLE='IDL Image Viewer', /COLUMN)

  ; 两个控件：按钮和绘图区
  button = WIDGET_BUTTON(base, VALUE='Open Image', XSIZE=600)
  draw = WIDGET_DRAW(base, XSIZE=600, YSIZE=400, RETAIN=2)

  WIDGET_CONTROL, base, SET_UVALUE=draw
  WIDGET_CONTROL, base, /REALIZE

  XMANAGER, 'gui_demo', base, EVENT_HANDLER='gui_event'

END
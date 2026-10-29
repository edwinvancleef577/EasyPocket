EasyPocket=EasyPocket or {}
local EP=EasyPocket
EP.languages={{"auto","Automatic"},{"enUS","English"},{"deDE","Deutsch"},{"frFR","Français"},
 {"esES","Español"},{"ptBR","Português"},{"ruRU","Russian / Русский"},{"koKR","Korean / 한국어"},{"zhCN","Chinese / 简体中文"}}
local codes={"deDE","frFR","esES","ptBR","ruRU","koKR","zhCN"}
local rows={
 {"Automatic","Automatisch","Automatique","Automático","Automático","Автоматически","자동","自动"},
 {"Pocket","Tasche","Sac","Bolsa","Bolsa","Сумка","가방","口袋"},
 {"My spells","Meine Zauber","Mes sorts","Mis hechizos","Meus feitiços","Мои заклинания","내 주문","我的法术"},
 {"Name","Name","Nom","Nombre","Nome","Название","이름","名称"},
 {"Icon","Icon","Icône","Icono","Ícone","Значок","아이콘","图标"},
 {"Choose icon","Icon wählen","Choisir l'icône","Elegir icono","Escolher ícone","Выбрать значок","아이콘 선택","选择图标"},
 {"Delete pocket","Tasche löschen","Supprimer le sac","Eliminar bolsa","Excluir bolsa","Удалить сумку","가방 삭제","删除口袋"},
 {"Really delete?","Wirklich löschen?","Confirmer ?","¿Eliminar?","Excluir mesmo?","Точно удалить?","정말 삭제할까요?","确定删除？"},
 {"Pocket window","Taschenfenster","Fenêtre du sac","Ventana de bolsa","Janela da bolsa","Окно сумки","가방 창","口袋窗口"},
 {"Position","Position","Position","Posición","Posição","Положение","위치","位置"},
 {"Free","Frei beweglich","Déplaçable","Movimiento libre","Movimento livre","Свободно","자유 이동","自由移动"},
 {"Fixed","Fest verankert","Fixe","Fija","Fixa","Закреплено","고정","固定"},
 {"Relative to pocket","Relativ zur Tasche","Relative au sac","Relativa a la bolsa","Relativa à bolsa","Относительно сумки","가방 기준","相对口袋"},
 {"Design","Design","Style","Diseño","Estilo","Стиль","디자인","样式"},
 {"Current","Aktuell","Actuel","Actual","Atual","Текущий","기존","当前"},
 {"Classic","Klassisch","Classique","Clásico","Clássico","Классический","클래식","经典"},
 {"pfUI style","PFUI-Stil","Style pfUI","Estilo pfUI","Estilo pfUI","Стиль pfUI","pfUI 스타일","pfUI 风格"},
 {"Width","Breite","Largeur","Ancho","Largura","Ширина","너비","宽度"},
 {"Height","Höhe","Hauteur","Alto","Altura","Высота","높이","高度"},
 {"General","Allgemein","Général","General","Geral","Общее","일반","通用"},
 {"Language","Sprache","Langue","Idioma","Idioma","Язык","언어","语言"},
 {"Debug","Debug","Diagnostic","Depuración","Diagnóstico","Диагностика","디버그","调试"},
 {"Close","Schließen","Fermer","Cerrar","Fechar","Закрыть","닫기","关闭"},
 {"New pocket","Neue Tasche","Nouveau sac","Nueva bolsa","Nova bolsa","Новая сумка","새 가방","新建口袋"},
 {"Create a pocket with +.","Mit + eine Tasche erstellen.","Créer un sac avec +.","Crea una bolsa con +.","Crie uma bolsa com +.","Создайте сумку кнопкой +.","+ 버튼으로 가방을 만드세요.","使用 + 创建口袋。"},
 {"Click: select and open pocket","Klick: Tasche auswählen und öffnen","Clic : choisir et ouvrir","Clic: seleccionar y abrir","Clique: selecionar e abrir","Нажатие: выбрать и открыть","클릭: 선택 및 열기","点击：选择并打开"},
 {"Click: open / close pocket","Klick: Tasche öffnen / schließen","Clic : ouvrir / fermer","Clic: abrir / cerrar","Clique: abrir / fechar","Нажатие: открыть / закрыть","클릭: 열기 / 닫기","点击：打开 / 关闭"},
 {"Drag: place on action bar","Ziehen: auf die Aktionsleiste legen","Glisser vers la barre d'actions","Arrastra a la barra de acción","Arraste para a barra de ações","Перетащите на панель действий","드래그: 행동 단축바에 놓기","拖动：放到动作条"},
 {"Drop a spell here","Zauber hierher ziehen","Déposer un sort ici","Suelta un hechizo aquí","Solte um feitiço aqui","Перетащите заклинание сюда","여기에 주문 놓기","将法术拖到此处"},
 {"Drag from the spellbook into the pocket.","Zauber aus dem Zauberbuch in die Tasche ziehen.","Glisser un sort du grimoire dans le sac.","Arrastra un hechizo del libro a la bolsa.","Arraste um feitiço do livro para a bolsa.","Перетащите заклинание из книги в сумку.","주문책의 주문을 가방에 놓으세요.","将法术书中的法术拖入口袋。"},
 {"Right-click: remove; drag: move spell","Rechtsklick: entfernen · Ziehen: Zauber verschieben","Clic droit : retirer ; glisser : déplacer","Clic derecho: quitar; arrastrar: mover","Clique direito: remover; arrastar: mover","Правая кнопка: убрать; перетаскивание: переместить","우클릭: 제거 · 드래그: 주문 이동","右键：移除；拖动：移动法术"},
 {"Shift-drag or drag border: move window","Umschalt-Ziehen oder Rand ziehen: Fenster verschieben","Maj-glisser ou glisser le bord : déplacer","Mayús-arrastrar o arrastrar borde: mover ventana","Shift-arrastar ou arrastar borda: mover janela","Shift-перетаскивание или край: двигать окно","Shift 드래그 또는 테두리 드래그: 창 이동","Shift 拖动或拖动边框：移动窗口"},
 {"Edit after combat.","Bitte erst nach dem Kampf bearbeiten.","Modifier hors combat.","Edita fuera de combate.","Edite fora de combate.","Изменяйте вне боя.","전투 종료 후 편집하세요.","请在战斗结束后编辑。"},
 {"Pocket is full.","Die Tasche ist voll.","Le sac est plein.","La bolsa está llena.","A bolsa está cheia.","Сумка полна.","가방이 가득 찼습니다.","口袋已满。"},
 {"Move occupied cells before shrinking.","Vor dem Verkleinern die betroffenen Plätze leeren.","Libérer les cases concernées avant de réduire.","Vacía las casillas afectadas antes de reducir.","Esvazie os espaços afetados antes de reduzir.","Освободите нужные ячейки перед уменьшением.","크기를 줄이기 전에 해당 칸을 비우세요.","缩小前请清空受影响的格子。"},
 {"Pocket deleted.","Diese Tasche wurde gelöscht.","Ce sac a été supprimé.","Esta bolsa se eliminó.","Esta bolsa foi excluída.","Эта сумка удалена.","삭제된 가방입니다.","该口袋已删除。"},
 {"Spell not in spellbook.","Zauber nicht im Zauberbuch.","Sort absent du grimoire.","Hechizo no disponible.","Feitiço não disponível.","Заклинания нет в книге.","주문책에 없는 주문입니다.","法术不在法术书中。"},
 {"Clear the cursor first.","Bitte zuerst den Mauszeiger leeren.","Vider le curseur d'abord.","Vacía primero el cursor.","Esvazie o cursor primeiro.","Сначала освободите курсор.","먼저 커서를 비우세요.","请先清空鼠标携带内容。"},
 {"No free macro slots.","Kein freier Makroplatz vorhanden.","Aucun emplacement de macro libre.","No hay espacio para macros.","Sem espaços de macro livres.","Нет свободных мест для макросов.","빈 매크로 칸이 없습니다.","没有空闲宏位置。"},
 {"Could not create macro.","Makro konnte nicht erstellt werden.","Création de macro impossible.","No se pudo crear la macro.","Não foi possível criar a macro.","Не удалось создать макрос.","매크로를 만들 수 없습니다.","无法创建宏。"},
 {"Click: open menu","Klick: Menü öffnen","Clic : ouvrir le menu","Clic: abrir menú","Clique: abrir menu","Нажатие: открыть меню","클릭: 메뉴 열기","点击：打开菜单"},
 {"Drag: move icon","Ziehen: Icon verschieben","Glisser : déplacer l'icône","Arrastrar: mover icono","Arrastar: mover ícone","Перетаскивание: двигать значок","드래그: 아이콘 이동","拖动：移动图标"},
 {"Use this icon","Dieses Icon verwenden","Utiliser cette icône","Usar este icono","Usar este ícone","Использовать значок","이 아이콘 사용","使用此图标"},
 {"Ready","Bereit","Prêt","Listo","Pronto","Готово","준비됨","就绪"},
 {"Not started","Nicht gestartet","Non démarré","Sin iniciar","Não iniciado","Не запущено","시작되지 않음","尚未启动"},
 {"Error","Fehler","Erreur","Error","Erro","Ошибка","오류","错误"},
 {"Status","Status","État","Estado","Estado","Состояние","상태","状态"},
 {"Select text, Ctrl+A, Ctrl+C to copy.","Text anklicken · Strg+A · Strg+C zum Kopieren.","Sélectionner le texte, Ctrl+A, Ctrl+C.","Selecciona el texto, Ctrl+A, Ctrl+C.","Selecione o texto, Ctrl+A, Ctrl+C.","Выберите текст, Ctrl+A, Ctrl+C.","텍스트 선택 후 Ctrl+A, Ctrl+C로 복사.","选择文本后按 Ctrl+A、Ctrl+C 复制。"},
 {"Error details: menu > Debug.","Fehlerdetails: Menü > Debug.","Détails : menu > Diagnostic.","Detalles: menú > Depuración.","Detalhes: menu > Diagnóstico.","Подробности: меню > Диагностика.","오류 정보: 메뉴 > 디버그.","错误详情：菜单 > 调试。"},
 {"Loaded. Open the minimap menu or /ep.","Geladen. Menü am Minimap-Icon oder mit /ep öffnen.","Chargé. Menu de minicarte ou /ep.","Cargado. Menú del minimapa o /ep.","Carregado. Menu do minimapa ou /ep.","Загружено. Меню миникарты или /ep.","로드됨. 미니맵 메뉴 또는 /ep.","已加载。使用小地图菜单或 /ep。"},
}
EP.translations={enUS={}}
for _,code in ipairs(codes) do EP.translations[code]={} end
for _,row in ipairs(rows) do
    EP.translations.enUS[row[1]]=row[1]
    for i,code in ipairs(codes) do EP.translations[code][row[1]]=row[i+1] end
end
function EP.Locale()
    local lang=(EP.db and EP.db.language) or (EasyPocketDB and EasyPocketDB.language) or "auto"
    if lang=="auto" then lang=GetLocale and GetLocale() or "enUS" end
    if lang=="enGB" then lang="enUS" elseif lang=="esMX" then lang="esES" end
    return EP.translations[lang] and lang or "enUS"
end
function EP.L(key) return (EP.translations[EP.Locale()] or {})[key] or key end

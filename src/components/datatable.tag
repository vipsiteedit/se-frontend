| import 'components/loader.tag'
| import Sortable from 'sortablejs'
| import 'colresizable/colResizable-1.6.min.js'

datatable
    .thead
        datatable-row
            datatable-head-cell(each='{ col, i in cols }', name='{ col.name }', title='{ col.title }', onclick='{ parent.headCellClick }',
            style='{ col.width ? "width: " + col.width : "" }', class='{ col.classes }', no-reorder)
                | { col.value }
    .tbody(if='{ !opts.loader }', ontouchmove='{ tableScroll }')
        datatable-row(each='{ row in rows }', class='{ "bg-info": row.__selected__ }'
        onclick='{ rowClick }',ontouchstart='{ rowTouchStart }', ontouchend='{ rowTouchEnd }', oncontextmenu='{ rowContext }')
            #{'yield'}
    loader(if='{ opts.loader }')
    //, draggable='{ "true": row.__selected__ && opts.reorder }',

    style(scoped).
        :scope {
            display: table;
            border-spacing: 2px;
            box-sizing: border-box;
            text-indent: 0;

            border-spacing: 0;
            border-collapse: collapse;

            width: 100%;
            max-width: 100%;
            margin-bottom: 20px;
        }

        .thead {
            display: table-header-group;
            vertical-align: middle;
        }

        .tbody {
            display: table-row-group;
            vertical-align: middle;
            position: relative;
        }

        .table-responsive > :scope {
            margin-bottom: 0;
        }

    script(type='text/babel').
        var self = this
        Object.defineProperty(self.root, 'value', {
            get: function () {
                return self.rows
            },
            set: function (value) {
                self.rows = value
            }
        })

        function changeEvent() {
            var event = document.createEvent('Event')
            event.initEvent('change', true, true)
            self.root.dispatchEvent(event);
        }

        // Заголовок
        self.headCellClick = function (e) {
            if (!opts.sortable) return
            if (this.col.name === '') return
            this.col.dir = !this.col.dir ? 'ASC' : this.col.dir === 'ASC' ? 'DESC' : 'ASC'

            var name = this.col.name
            for (var i = 0; i < this.cols.length; i++)
                if (this.cols[i].name !== name) {
                    delete this.cols[i].dir
                }
            self.trigger('sort')
        }

        // Колонки
        self.getSortedColumn = function () {
            return self.cols.filter(function (item) {
                return (item.dir && item.dir !== '')
            })[0]
        }

        self.getVisibleColumns = function () {
            return self.cols.filter(function (item) {
                return !item.hidden
            })
        }

        self.getHiddenColumns = function () {
            return self.cols.filter(function (item) {
                return item.hidden
            })
        }

        self.toggleColumn = function (name) {
            for (var i = 0; i < self.cols.length; i++)
                if (self.cols[i].name == name) {
                    var hidden = self.cols[i].hidden ? true : false
                    break
                }

            hidden ? self.showColumn(name) : self.hideColumn(name)
            self.trigger('column-toggle', name, hidden)
        }

        self.hideColumn = function (name) {
            var nodeList = self.root.querySelectorAll('[name="' + name + '"]')

            for (var i = 0; i < nodeList.length; i++)
                nodeList[i].style.display = 'none'

            for (var k = 0; k < self.cols.length; k++)
                if (self.cols[k].name == name) {
                    self.cols[k].hidden = true
                    break
                }
        }

        self.showColumn = function (name) {
            var nodeList = self.root.querySelectorAll('[name="' + name + '"]')

            for (var i = 0; i < nodeList.length; i++)
                nodeList[i].style.display = ''

            for (var k = 0; k < self.cols.length; k++)
                if (self.cols[k].name == name) {
                    delete self.cols[k].hidden
                    break
                }
        }

        // Строки
        var doubleClick = opts.dblclick || function (e) {}


        /** Исключить из списка
         * @param array nodes  нумерованный массив с информацией об элементах
         * @param str exception id редактируемой группы для исключения из списка
         */
        self.exceptionFilter = (nodes, exception) => {
            exceptionFilter(nodes, exception)
        }
        /** Исключения из списка
         * @param array nodes  нумерованный массив с информацией об элементах
         * @param str exception id редактируемой группы для исключения из списка
         * @return bool true - исключение найденно
         */
        function exceptionFilter(nodes, exception) {
            if (nodes instanceof Array) {
                nodes.forEach(function(item, index, object) {
                    if (item["id"] == exception) {
                        object.splice(index, 1)
                        return true
                    }
                })
            }
        }


        function setRowSelected (row) {
            Object.defineProperty(row, '__selected__', {
                configurable: true,
                enumerable: false,
                value: true
            })
            observable.trigger('catalog-recount')
        }

        function setRowUnselected (row) {
            delete row.__selected__
        }

        function selectOneRow (e) {
            self.rows.forEach(function (item) {
                setRowUnselected(item)
            })
            setRowSelected(e.item.row)
        }

        function selectRows (e) {
            if (e.item.row.__selected__)
                setRowUnselected(e.item.row)
            else
                setRowSelected(e.item.row)
            observable.trigger('catalog-recount')
        }

        function getSelectY() {
            var el = self.root.querySelector('.bg-info')
            var _y = 0;
            var scrollY = 0;
            var height = document.documentElement.clientHeight;
            while( el && !isNaN( el.offsetTop ) ) {
                _y += el.offsetTop - el.scrollTop;
                el = el.offsetParent;
            }
            if (_y > (height / 2) + window.scrollY) {
                scrollY = _y - (height / 2);
                window.scrollTo(0, scrollY);
            }
            if (_y < (height / 2) + window.scrollY) {
                scrollY = _y - (height / 2);
                if (scrollY < 0) scrollY = 0;
                window.scrollTo(0, scrollY);
            }

            console.log(_y, window.scrollY, height, scrollY)

            return window.scrollY;
        }

        self.selectRangeRows = function (start, end) {
            for (var i = 0; i < self.rows.length; i++) {
                if (i >= start && i <= end)
                    setRowSelected(self.rows[i])
                else
                    setRowUnselected(self.rows[i])
            }
            self.update()
        }

        var lastSelectedRowIndex = 0

        self.rowContext = function (e) {
            if(typeof(self.handlers.contextMenu) === "function"){
                if(self.getSelectedRows() > 0){
                    selectOneRow(e);
                }
                return self.handlers.contextMenu( e, e.item.row);
            }
            return true;
        }

        self.rowClick = function (e) {

            var currentSelectedRowIndex = self.rows.indexOf(e.item.row)

            var currentClick = Date.now()
            var clickLength = currentClick - this.__lastClick__

            if (clickLength < 300 && clickLength > 0 && !e.ctrlKey && !e.metaKey && !e.shiftKey) {
                currentClick = 0
                doubleClick(e)
            }

            if (!e.shiftKey) {
                if (!e.ctrlKey && !e.metaKey)
                    selectOneRow(e)
                else
                    selectRows(e)
            } else {
                if (currentSelectedRowIndex >= lastSelectedRowIndex)
                    self.selectRangeRows(lastSelectedRowIndex, currentSelectedRowIndex)
                else
                    self.selectRangeRows(currentSelectedRowIndex, lastSelectedRowIndex)
            }

            self.trigger('row-selected', self.getSelectedRowsCount(), e.item.row)

            if (!e.shiftKey)
                lastSelectedRowIndex = currentSelectedRowIndex
            this.__lastClick__ = currentClick
        }

        var tbodyScroll = false
        self.tableScroll = function (e) {
            tbodyScroll = true
            return true
        }

        self.rowTouchStart = function (e) {
            var _this = this
            _this.__tapLong__ = false
            tbodyScroll = false
            _this.__lastTapStart__ = Date.now()

            _this.__tapStartTimer__ = setTimeout(function () {
                if (!tbodyScroll) {
                    selectRows(e)
                    self.trigger('row-selected', self.getSelectedRowsCount(), e.item.row)
                    _this.__tapLong__ = true
                    self.update()
                }
            }, 400)

            return true
        }

        self.rowTouchEnd = function (e) {
            var currentTap = Date.now()
            var tapLength = currentTap - this.__lastTapEnd__

            if (this.__tapStartTimer__)
                clearTimeout(this.__tapStartTimer__)

            if (!tbodyScroll && !this.__tapLong__) {
                selectOneRow(e)
                self.trigger('row-selected', self.getSelectedRowsCount(), e.item.row)
            }

            if (tapLength < 500 && tapLength > 0) {
                currentTap = 0
                doubleClick(e)
            }

            this.__lastTapEnd__ = currentTap
            return true
        }

        self.getSelectedRows = function () {
            if(self.rows){
                return self.rows.filter(function (item) {
                    return item.__selected__ == true
                })
            }
            return [];
        }

        self.selectAllRows = function (all) {
            all = all || true;

            var select = (self.getSelectedRowsCount() == self.rows.length);

            if(select && all) select = true;

            for (var i = 0; i < self.rows.length; i++) {
                select ? setRowUnselected(self.rows[i]) : setRowSelected(self.rows[i]);
            }

            self.trigger('row-selected', self.getSelectedRowsCount(), self.rows[i]);
            self.update();
            self.reload();
            return !select;
        }


        self.getUnselectedRows = function () {
            return self.rows.filter(function (item) {
                return !item.__selected__
            })
        }

        self.getSelectedRowsCount = function () {
            return self.getSelectedRows().length
        }

        // Прочее
        self.stopPropagation = function (e) {
            e.stopPropagation()
            e.stopImmediatePropagation()
        }

        self.reload = function () {
            self.cols = opts.cols || []
            self.rows = opts.rows || []
            self.handlers = opts.handlers || {}
        }

        self.reorderNext = function() {
            if (!opts.reorder) return
            var srows = self.getSelectedRows()
            //console.log(srows)
            var newIndex = 0, oldIndex = 0
            if (srows.length > 0) {
                for (var i = 0; i < self.rows.length; i++) {
                    if (srows[0].id == self.rows[i].id) {
                        oldIndex = i
                        break
                    }
                }
                if (oldIndex + 1 > self.rows.length) return
                newIndex = oldIndex + 1
                self.rows.splice(newIndex, 0, self.rows.splice(oldIndex, 1)[0])
                var temp = self.rows
                self.rows = []
                changeEvent()
                self.rows = temp
                changeEvent()
                self.trigger('reorder-end', newIndex, oldIndex)
            }
        }

        self.reorderPrev = function() {
            if (!opts.reorder) return
            var srows = self.getSelectedRows()
            var newIndex = 0, oldIndex = 0
            if (srows.length > 0) {
                for (var i = 0; i < self.rows.length; i++) {
                    if (srows[0].id == self.rows[i].id) {
                        oldIndex = i
                        break
                    }
                }
                if (oldIndex - 1 < 0) return
                newIndex = oldIndex - 1
                self.rows.splice(newIndex, 0, self.rows.splice(oldIndex, 1)[0])
                var temp = self.rows
                self.rows = []
                changeEvent()
                self.rows = temp
                changeEvent()
                self.trigger('reorder-end', newIndex, oldIndex)
            }
        }

        self.reorderKey = () => {
        // Горячие клавиши
            document.onkeydown = function(e) {
                if(e.ctrlKey){
                    if(e.keyCode == 38){
                        //UP
                        self.reorderPrev();
                        console.log(getSelectY())
                        return false;
                    }
                    if(e.keyCode == 40){
                        //DOWN
                        self.reorderNext();
                        console.log(getSelectY())
                        return false;
                    }
                }
            }
        }

        self.on('updated', function () {
            var colsHidden = self.getHiddenColumns()
            colsHidden.forEach(function (item) {
                self.hideColumn(item.name)
            })
        })

        self.on('update', function () {
            self.reload()
            self.reorderKey()
        })

        var sortableOption = {
            delay: 200,
            animation: 100,
            scroll: true,
            sort: true,
            chosenClass: "sortable-chosen",
            onEnd: function (evt) {
                self.rows.splice(evt.newIndex, 0, self.rows.splice(evt.oldIndex, 1)[0])
                var temp = self.rows
                self.rows = []
                changeEvent()
                self.rows = temp
                changeEvent()
                self.trigger('reorder-end', evt.newIndex, evt.oldIndex)
            }
        }

        self.on('mount', function () {
            self.root.name = opts.name

            if (opts.reorder) {
                var el = self.root.querySelector('.tbody')
                Sortable.create(el, sortableOption)
            }

            $(self.root).colResizable({
                resizeMode : 'flex',
                liveDrag : true
            });


            self.reload()
        })


datatable-head-cell
    #{'yield'}
    i(class='{ "fa fa-chevron-up": col.dir == "DESC", "fa fa-chevron-down": col.dir == "ASC" }')
    grip

    style(scoped).
        :scope {
            display: table-cell;
            vertical-align: inherit;
            font-weight: bold;
            padding: 1px;
            position: relative;

            user-select: none;
            -khtml-user-select: none;
            -o-user-select: none;
            -ms-user-select: none;
            -moz-user-select: -moz-none;
            -webkit-user-select: none;
            cursor: pointer;

            background-color: #eceeef;
        }

        .thead :scope {
            padding: 5px;
            border-bottom: 2px solid #ddd;
        }

        .table-responsive > datatable > .thead > datatable-row > :scope {
            white-space: nowrap;
        }

    script.
        var self = this

        self.col = self.parent.col

        self.on('update', () => {
            self.handlers = self.parent.handlers
        })


datatable-row
    #{'yield'}

    style(scoped).
        :scope {
            display: table-row;
            vertical-align: inherit;

            user-select: none;
            -khtml-user-select: none;
            -o-user-select: none;
            -ms-user-select: none;
            -moz-user-select: -moz-none;
            -webkit-user-select: none;
            cursor: default;
        }

    script.
        var self = this

        Object.defineProperties(self, {
            '__lastClick__': {
                writable: true,
                configurable: true,
                enumerable: false,
                value: 0
            },
            '__lastTapStart__': {
                writable: true,
                configurable: true,
                enumerable: false,
                value: 0
            },
            '__lastTapEnd__': {
                writable: true,
                configurable: true,
                enumerable: false,
                value: 0
            },
            '__tapStartTimer__': {
                writable: true,
                configurable: true,
                enumerable: false,
                value: false
            },
            '__tapLong__': {
                writable: true,
                configurable: true,
                enumerable: false,
                value: false
            }
        })

        self.on('update', () => {
            self.cols = self.parent.cols
            self.handlers = self.parent.handlers
            self.headCellClick = self.parent.headCellClick
        })


datatable-cell
    #{'yield'}

    style(scoped).
        :scope {
            display: table-cell;
            vertical-align: inherit;
            text-align: inherit;
        }

        .tbody :scope {
            padding: 5px;
            border-top: 1px solid #ddd;
        }

        .table-responsive > datatable > .tbody > datatable-row > :scope {
            white-space: nowrap;
        }

        :scope input {
            width: 100%;
        }

        :scope[contenteditable]:focus {
            background-color: #fff;
            outline: 1px solid #ccc;
        }

    script.
        var self = this

        self.on('update', function () {
            if (self._parent && self._parent.row)
                self.row = self._parent.row
            else if (self.parent && self.parent.row)
                self.row = self.parent.row

            if (self._parent && self._parent.handlers)
                self.handlers = self._parent.handlers
            else if (self.parent && self.parent.handlers)
                self.handlers = self.parent.handlers
        })

        if (self._parent && self._parent.row)
            self.stopPropagation = self._parent.stopPropagation

datatable-search-select
    button.btn.btn-default.dropdown-toggle(type='button', data-toggle='dropdown')
        i.fa.fa-search &nbsp;
        span.caret
    ul.dropdown-menu(class='{ "dropdown-menu-right": opts.align == "right" }')
        virtual(each='{ col in opts.fields }')
            li(onclick='{ toggleField }')
                a
                    i.fa.fa-check(style='{ col.active ? "visibility: visible;" : "visibility: hidden;" }')
                    |  { col.title }
    style(scoped).
        :scope {
            position: relative;
        }

        .dropdown-menu > li {
            user-select: none;
            -khtml-user-select: none;
            -o-user-select: none;
            -moz-user-select: -moz-none;
            -webkit-user-select: none;
            cursor: pointer;
        }

    script.
        var self = this

        self.toggleField = function (e) {
             e.stopPropagation()
             e.stopImmediatePropagation()
             let item = e.item.col
             item.active = !item.active
             self.update()
             opts.store()
        }

datatable-columns-select
    button.btn.btn-default.dropdown-toggle(type='button', data-toggle='dropdown')
        i.fa.fa-list &nbsp;
        span.caret
    ul.dropdown-menu(class='{ "dropdown-menu-right": opts.align == "right" }')
        virtual(each='{ col in opts.table.cols }')
            li(class='{ (!col.hidden && parent.opts.table.getVisibleColumns().length === 1) ? "disabled" : "" }',
            onclick='{ (!col.hidden && parent.opts.table.getVisibleColumns().length === 1) ? stopPropagation : toggleColumn }')
                a
                    i.fa.fa-check(style='{ !col.hidden ? "visibility: visible;" : "visibility: hidden;" }')
                    |  { col.value }
    style(scoped).
        :scope {
            position: relative;
        }

        .dropdown-menu > li {
            user-select: none;
            -khtml-user-select: none;
            -o-user-select: none;
            -moz-user-select: -moz-none;
            -webkit-user-select: none;
            cursor: pointer;
        }

    script.
        var self = this

        self.stopPropagation = function (e) {
            e.stopPropagation()
            e.stopImmediatePropagation()
        }

        self.toggleColumn = function (e) {
            e.stopPropagation()
            e.stopImmediatePropagation()
            opts.table.toggleColumn(e.item.col.name)
        }

grip(onclick='{ cellClick }')

    style(scoped).
        :scope {
            width: 3px;
            height: 31px;
            top: 0;
            position: absolute;
            right: 0;
            cursor: w-resize;
            background-color: #DFE8EC;
        }

        :scope:hover {
            background-color: #697276;
        }

    script.
        var self = this

        self.cellClick = e => {
            e.preventDefault()
        }



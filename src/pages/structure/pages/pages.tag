| import 'components/catalog.tag'
| import './page-new-modal.tag'

pages
    .row
        .col-md-12.col-xs-12.col-sm-12
            catalog(
                search          = 'true',
                sortable        = 'true',
                object          = 'SitePages',
                cols            = '{ cols }',
                combine-filters = 'true',
                add             = '{ permission(add, "site", "0100") }',
                remove          = '{ permission(remove, "site", "0001") }',
                dblclick        = '{ permission(pageOpen, "site", "1000") }',
                handlers        = '{ handlers }',
                allselect       = "true",
                reload          = 'true',
                store           = 'pages-list'
            )
                #{'yield'}(to='filters')
                // меню действий
                #{'yield'}(to='head')
                    .dropdown(if='{ checkPermission("site", "0010") && selectedCount > 0 }', style='display: inline-block;')
                        button.btn.btn-default.dropdown-toggle(data-toggle="dropdown", aria-haspopup="true", type='button', aria-expanded="true")
                            | Действия&nbsp;
                            span.caret
                        ul.dropdown-menu
                            li(onclick='{ handlers.multiEdit }', class='{ disabled: selectedCount < 2 }')
                                a(href='#')
                                    i.fa.fa-fw.fa-pencil
                                    |  Мультиредактирование страниц
                            li(onclick='{ handlers.cloneProduct }', class='{ disabled: selectedCount > 1 }')
                                a(href='#')
                                    i.fa.fa-fw.fa-clone
                                    |  Клонирование страницы
                            li.divider
                            li(onclick='{ handlers.toggleSelected }')
                                a(href='#', data-field='enabled')
                                    i.fa.fa-fw.fa-eye
                                    |  Видимость (вкл/выкл)
                    #{'yield'}(to='head')

                // лист каталога товаров
                #{'yield'}(to='body')
                    datatable-cell(name='title', style="width: 100%; overflow: hidden; text-overflow: ellipsis;") { row.title }                     
                    datatable-cell(name='name', style="min-width: 150px; overflow: hidden; text-overflow: ellipsis;", title='{ row.name }') { row.name }
                    datatable-cell(name='enabled', style="max-width: 50px;")
                        button.btn.btn-default.btn-sm(type='button',
                        onclick='{ handlers.permission(handlers.boolChange, "products", "0010") }',
                        ontouchend='{ handlers.permission(handlers.boolChange, "products", "0010") }',
                        ontouchstart='{ stopPropagation }',
                        disabled='{ !handlers.checkPermission("products", "0010") }')
                            i(class='fa { row.enabled == "Y" ? "fa-eye text-active" : "fa-eye-slash text-noactive" } ')

    style(scoped).
        :scope {
            display: block;
            position: relative;
        }
        .text-active {
            color: #000;
        }
        .text-noactive {
            color: #ccc;
        }

        .table td {
            vertical-align: middle !important;
        }

    script(type='text/babel').
        var self = this

        self.mixin('permissions')
        self.mixin('remove')
        self.collection = 'SitePages'

        self.add = function(e) {
            /*
            * СОЗДАНИЕ СТРАНИЦЫ
            * передаем в Pages Save
            */

            modals.create('page-new-modal', {
                type: 'modal-primary',
                submit() {
                    var _this = this
                    var params = {
                        name: this.name.value,
                        idGroup: self.selectedCategory,
                        idBrand: self.selectedBrand,
                        curr: self.basecurr
                    }
                    _this.error = _this.validation.validate(_this.item, _this.rules)
                    if (!_this.error) {
                        API.request({
                            object: self.collection,
                            method: 'Save',
                            data: params,
                            success(response, xhr) {
                                popups.create({title: 'Успех!', text: 'Страница добавлена!', style: 'popup-success'})
                                _this.modalHide()
                                self.tags.catalog.reload()
                                if (response && response.id)
                                    riot.route(`/site/pages/${response.id}`)
                            }
                        })
                    }
                }
            })
        }

        self.cols = [
            { name:'title', value:'Заголовок'},
            { name:'name', value:'Наименование'},
            { name:'enabled', value:'Вид'},
        ]


        // сохранение измененных через лист параметров
        self.handlers = {
            checkPermission: self.checkPermission,
            permission: self.permission,
            boolChange(e) {
                var _this = this
                e.stopPropagation()
                e.stopImmediatePropagation()

                if (_this.opts.name == 'presenceCount') {
                    this.row[this.opts.name]   = e.target.value
                    _this.row[_this.opts.name] = e.target.value
                } else if (_this.opts.name == 'isMarket')
                    _this.row[_this.opts.name] = _this.row[_this.opts.name] ? 0 : 1
                else
                    _this.row[_this.opts.name] = _this.row[_this.opts.name] === 'Y' ? 'N' : 'Y'

                self.update()

                var params = {}
                params.id = _this.row.id
                params[_this.opts.name] = _this.row[_this.opts.name]

                params = self.tags.catalog.allParams(params);
                API.request({
                    object: self.collection,
                    method: 'Save',
                    data: params,
                    error(response) {
                        if (_this.opts.name == 'isMarket')
                            _this.row[_this.opts.name] = _this.row[_this.opts.name] ? 0 : 1
                        else
                            _this.row[_this.opts.name] = _this.row[_this.opts.name] === 'Y' ? 'N' : 'Y'
                        self.update()
                    }
                })
            },
            // селекторы
            toggleSelected(e) {
                let field = e.target.getAttribute('data-field')

                let oldValues = {}
                let rows = this.tags.datatable.getSelectedRows()
                let ids = rows.map(item => item.id)
                let newValue = rows[0][field] === 'Y' ? 'N' : 'Y'

                let params = self.tags.catalog.getSelectedMode()
                params[field] = newValue

                rows.forEach(function(item) {
                    oldValues[item.id] = { [field]: item[field] }
                    item[field] = newValue
                })
                API.request({
                    object: self.collection,
                    method: 'Save',
                    data: params,
                    error(response) {
                        rows.forEach(function(item) {
                            item[field] = oldValues[item.id][field]
                        })

                        self.update()
                    }
                })
            },
            toggleBool(e) {
                let field = e.target.getAttribute('data-field')
                let oldValues = {}
                let rows = this.tags.datatable.getSelectedRows()
                let ids = rows.map(item => item.id)
                let newValue = rows[0][field] ? 0 : 1

                let params = self.tags.catalog.getSelectedMode()
                params[field] = newValue

                rows.forEach(function(item) {
                    oldValues[item.id] = { [field]: item[field] }
                    item[field] = newValue
                })
                API.request({
                    object: self.collection,
                    method: 'Save',
                    data: params,
                    error(response) {
                        rows.forEach(function(item) {
                            item[field] = oldValues[item.id][field]
                        })
                        self.update()
                    }
                })
            },

            // МЕНЮ ДЕЙСТВИЙ
            // мультиредактирование товаров
            multiEdit(e) {
                let ids = this.tags.datatable.getSelectedRows().map(item => item.id).join(',')
                riot.route(`/site/pages/multi?ids=${ids}`)
            },
            // клонирование товара
            cloneProduct(e) {
                let ids = this.tags.datatable.getSelectedRows().map(item => item.id).join(',')
                riot.route(`/site/pages/clone?id=${ids}`)
            },
            contextMenu( Event, SelectedRow){
                return true;
            }
        }

        self.pageOpen = e => riot.route(`/site/pages/${e.item.row.id}`)


        // перезагрузка каталога продуктов
        observable.on('pages-reload', function(item) {

            // принимаем группы для фильтрации
            if(item && item.name) {
                self.update()
                let items = self.tags.catalog.items
                if (items && items.length > 0)
                items.forEach((it, i) => {
                    if (it.__selected__) {
                        items[i].name = item.name
                        items[i].title = item.title
                        items[i].enabled = item.enabled
                        return
                    }
                })
                self.update()
            } else {
                self.update()
                self.tags.catalog.reload()
            }
        })

        self.one('updated', function() {
        })


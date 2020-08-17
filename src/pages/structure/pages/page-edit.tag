| import 'components/ckeditor.tag'
| import 'components/loader.tag'
| import 'components/autocomplete.tag'
| import 'components/checkbox-list-inline.tag'
| import parallel from 'async/parallel'

page-edit
    loader(if='{ loader }')
    virtual(hide='{ loader }')
        .btn-group
            a.btn.btn-default(href='#site/pages') #[i.fa.fa-chevron-left]
            button.btn.btn-default(if='{ checkPermission("site", "0010") }',
            class='{ item._edit_ ? "btn-success" : "btn-default" }', onclick='{ submit }', type='button')
                i.fa.fa-floppy-o
                |  Сохранить
            button.btn.btn-default(if='{ !isMulti }', onclick='{ reload }', title='Обновить', type='button')
                i.fa.fa-refresh
        .h4 { isMulti ? item.name || 'Мультиредактирование страниц' : isClone ? 'Клонирование товара' : item.name || 'Редактирование страницы' }

        // вкладки
        ul.nav.nav-tabs.m-b-2
            li.active
                a(data-toggle='tab', href='#page-edit-content', class="fa fa-shopping-bag", title="Содержание")
                    span.hidden-xs  Содержание
            li
                a(data-toggle='tab', href='#page-edit-sections', class="fa fa-sticky-note-o", title="Разделы")
                    span.hidden-xs  Разделы
            li
                a(data-toggle='tab', href='#page-edit-seo')
                    i.fa SEO
                    span.hidden-xs  Продвижение

        // вкладка-контент
        .tab-content
            #page-edit-content.tab-pane.fade.in.active
                // поля формы
                form(action='', onchange='{ change }', onkeyup='{ change }', method='POST')
                    .row
                        .col-md-6(if='{ !isMulti }')
                            .form-group(class='{ has-error: error.title }')
                                label.control-label Заголовок страницы
                                input.form-control(name='title', type='text', value='{ item.title }')
                                .help-block { error.title }
                        .col-md-6
                            .form-group
                                label.control-label Имя страницы
                                input.form-control(if='{ item.name=="home" }', name='name', value='{ item.name }' readonly='true')
                                .input-group(if='{ item.name!="home" }')
                                    input.form-control(name='name', value='{ item.name }')
                                    .input-group-btn(if='{ item.name!="home" }')
                                        .btn.btn-default(onclick='{ permission(translite, "site", "0010") }')
                                            | Транслитерация
                    .row
                        .col-md-2
                            .form-group
                                label.control-label Дизайн
                                select.form-control(name='skin' value='{ item.skin }')
                                    option(each='{ name in item.skinlist }', value='{ name }' selected='{ name==item.skin }') { name }
                        .col-md-2
                            .form-group
                                label.control-label Приоритет
                                input.form-control(name='priority', type='number', min=1 max=100 value='{ item.priority }')

                    .row
                        .col-md-12
                            .form-group
                                label.control-label Область заголовков
                                textarea.form-control(name='localjavascripthead', rows='4', value='{ item.localjavascripthead }')
                    .row
                        .col-md-10
                            .form-group
                                .checkbox-inline
                                    label
                                        input(type='checkbox', name='enabled', checked='{ (item.enabled == "Y") }', data-bool='Y,N')
                                        | Отображать на сайте
                                .checkbox-inline
                                    label
                                        input(type='checkbox', name='isSearch', checked='{ item.isMarket }')
                                        | Добавить в sitemap.xml


            // Полный текст
            #page-edit-sections.tab-pane.fade
                page-sectionss(name='text', value='{ item.sections }')

            // Редактировать товар seo
            #page-edit-seo.tab-pane.fade
                form(action='', onchange='{ change }', onkeyup='{ change }', method='POST')
                    .row
                        .col-md-12
                            .form-group
                                button.btn.btn-primary.btn-sm(each='{ seoTags }', title='{ note }', type='button'
                                onclick='{ seoTag.insert }', no-reorder) { name }
                            .form-group
                                label.control-label  Заголовок
                                input.form-control(name='title', type='text',
                                onfocus='{ seoTag.focus }', value='{ item.title }')
                            .form-group
                                label.control-label  Ключевые слова
                                input.form-control(name='keywords', type='text',
                                onfocus='{ seoTag.focus }', value='{ item.keywords }')
                            //.form-group
                                label.control-label Оглавление страницы (H1)
                                input.form-control(name='pageTitle', type='text',
                                onfocus='{ seoTag.focus }', value='{ item.pageTitle }')
                            .form-group
                                label.control-label  Описание
                                textarea.form-control(rows='5', name='description', onfocus='{ seoTag.focus }',
                                style='min-width: 100%; max-width: 100%;', value='{ item.description }')

    style(scoped).
        .color {
            height: 12px;
            width: 12px;
            display: inline-block;
            border: 1px solid #ccc;
        }
        a.fa span {
            font-family: "Helvetica Neue",Helvetica,Arial,sans-serif;;
        }

    script(type='text/babel').
        var self = this

        self.app = app
        self.item = {}
        self.seoTags = []
        self.loader = false
        self.error = false


        self.seoTag = new app.insertText()

        self.mixin('permissions')
        self.mixin('validation')
        self.mixin('change')

        self.rules = {
            title: 'empty'
        }


        self.afterChange = e => {
            let name = e.target.name
            delete self.error[name]
            self.error = {...self.error, ...self.validation.validate(self.item, self.rules, name)}
        }


        // Отправить
        self.submit = e => {
            var params = self.item

            if (self.isMulti) {
                self.error = false
                params = { ids: self.multiIds, ...self.item }
            } else {
                self.error = self.validation.validate(params, self.rules)
            }

            if (!self.error) {
                self.loader = true

                // запрос на сохранение товара
                API.request({
                    object: 'SitePages',
                    method: 'Save',
                    data: params,
                    success(response) {
                        self.item = response
                        popups.create({title: 'Успех!', text: 'Страница сохранена!', style: 'popup-success'})
                        if (self.isClone) {
                            riot.route(`/site/pages/${self.item.id}`)
                            observable.trigger('pages-reload')
                        } else
                        if (self.isMulti) {
                            riot.route(`/site/pages`)
                        } else
                            observable.trigger('pages-reload', self.item)
                    },
                    complete() {
                        self.loader = false
                        self.update()
                    }
                })
            }
        }


        // перевести
        self.translite = e => {
            var params = {vars:[self.item.title]}
            API.request({
                object: 'Functions',
                method: 'Translit',
                data: params,
                success(response, xhr) {
                    self.item.name = response.items[0]
                    self.update()
                }
            })
        }


        // Получить продукт
        function getPage(id, callback) {
            var params = {id}

            parallel([
                callback => {
                    API.request({
                        object: 'SitePages',
                        method: 'Info',
                        data: params,
                        success(response) {
                            self.item = response
                            callback(null, 'Page')
                        },
                        error(response) {
                            self.item = {}
                            callback('error', null)
                        }
                    })
                }, callback => {
                    API.request({
                        object: 'SeoVariable',
                        method: 'Fetch',
                        data: {type: 'pages'},
                        success(response) {
                            self.seoTags = response.items
                            callback(null, 'SEOTagsVars')
                        },
                        error(response) {
                            callback('error', null)
                        }
                    })
                }
            ], (err, res) => {
                    if (typeof callback === 'function')
                        callback.bind(this)()
            })
        }


        // перезагружать
        self.reload = () => {
            observable.trigger('page-edit', self.item.id)
        }

        // Продукты-редактировать
        observable.on('page-edit', id => {
            self.error = false
            self.isMulti = false
            self.isClone = false
            self.loader = true
            self.update()

            getPage(id, () => {
                self.loader = false
                self.update()
            })
        })

        // продукты-клон
        observable.on('page-clone', id => {
            self.error = false
            self.isMulti = false
            self.isClone = true
            self.loader = true
            self.update()

            // Получить продукт
            getPage(id, () => {
                self.loader = false
                delete self.item.id
                delete self.item.code
                self.item.images.forEach(item => {
                    delete item.id
                })
                self.item.modifications.forEach(item => {
                    item.items.forEach(mod => {
                        delete mod.article
                    })
                })

                self.update()
            })
        })


        // Продукты-мульти-редактирование
        observable.on('pages-multi-edit', ids => {
            self.error = false
            self.isMulti = true
            self.isClone = false
            self.item = {}
            self.multiIds = ids
            self.update()
        })

        self.on('update', () => {
            localStorage.setItem('SE_section', 'images')
        })

        self.on('mount', () => {
            riot.route.exec()
        })

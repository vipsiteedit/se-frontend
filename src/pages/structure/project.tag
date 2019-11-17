| import './pages/pages.tag'
| import './pages/page-edit.tag'

project
    ul(if='{ !edit }').nav.nav-tabs.m-b-2
        li(each='{ tabs }', class='{ active: name == tab }', title='{ title }', if='{ access }')
            a(href='#site/{ link }')
                i(class='{ icon }')
                span.hidden-xs &nbsp;{ title }
    .column
        pages(if='{ tab == "pages" && !edit }')
        page-edit(if='{ tab == "pages" && edit }')

    script(type='text/babel').
        var self = this
        self.tab = 'pages'

        self.edit = false
        var route = riot.route.create()

        self.tabs = [
            {title: 'Список страниц', name: 'pages', link: 'pages', icon: 'fa fa-shopping-bag', access: true },
            {title: 'Общие данные', name: 'project', link: 'project', icon: 'fa fa-folder-open', access: true},
            {title: 'Настройки', name: 'setting', link: 'setting', icon: 'fa fa-adn', access: true},
        ]

        route('/site/pages/([a-z0-9]+)', name => {
            self.tab = 'pages'
            observable.trigger('page-edit', name)
            self.edit = true
            self.update()
        })

        route('/site/pages/multi..', () => {
            let q = riot.route.query()
            let ids = q.ids.split(',')
            self.tab = 'pages'
            observable.trigger('pages-multi-edit', ids)
            self.edit = true
            self.update()
        })

        route('/site/pages/clone..', () => {
            let q = riot.route.query()
            let id = q.id
            self.tab = 'pages'
            observable.trigger('page-clone', id)
            self.edit = true
            self.update()
        })
        route('/site/pages', () => {
            self.edit = false
            self.tab = 'pages'
            self.update()
        })

        route('/site/project', () => {
            self.edit = false
            self.tab = 'project'
            self.update()
        })
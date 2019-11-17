| import debounce from 'lodash/debounce'
| import 'components/treeview.tag'

catalog-treemini
    .row
        .col-md-12
            .form-inline.m-b-2
                button.btn.btn-primary(if='{ opts.add }', onclick='{ opts.add }', type='button')
                    i.fa.fa-plus
                    |  {app.ml("Add")}
                button.btn.btn-success(if='{ opts.reload }', onclick='{ reload }', title='{app.ml("Update")}', type='button')
                    i.fa.fa-refresh
                button.btn.btn-danger(if='{ opts.remove && selectedCount }', onclick='{ remove }', title='{app.ml("Delete")}', type='button')
                    i.fa.fa-trash { (selectedCount > 1) ? "&nbsp;" : "" }
                    span.badge(if='{ selectedCount > 1 }') { selectedCount }
                #{'yield'}(from='head')

    .row.coltree
        .col-md-12
            treeview(nodes='{ nodes }', handlers='{ opts.handlers }', label-field='{ opts.labelField }',
            children-field='{ opts.childrenField }', loader='{ loader }', descendants='{ opts.descendants }')
                #{'yield'}(to='before')
                    #{'yield'}(from='before')
                #{'yield'}(to='after')
                    #{'yield'}(from='after')


    style(scoped).
        treenodes .treenode {
            padding: 5px;
        }

    script(type='text/babel').
        var self = this

        self.mixin('permissions')
        self.nodes = []
        self.selectedCount = 0
        self.handlers = opts.handlers


        self.reload = () => {
            self.trigger('reload')
            self.loader = true
            self.update()

            var params = {}
            params.isTree = true

            if (opts.name)
                params.name = opts.name

            if (opts.search && self.search) {
                params.searchText = self.search.value
            }

            API.request({
                object: opts.object,
                method: 'Fetch',
                data: params,
                success(response) {
                    self.nodes = response.items
                },
                complete() {
                    self.loader = false
                    self.update()
                }
            })
        }

        self.remove = e => {
        var _this = this

        let items = self.tags.treeview.getSelectedNodes()
        let itemsToRemove = items.map(i => i.id)

        if (opts.remove)
            opts.remove.bind(this, e, itemsToRemove, self)()
        }

        self.find = debounce(e => {
        self.reload()
        }, 400)

        self.on('mount', () => {
            self.reload()
        })

        self.on('update', () => {
            self.handlers = opts.handlers
        })

        self.one('updated', () => {
            self.tags.treeview.on('nodeselect', (item, count) => {
            self.selectedCount = count
            self.update()
        })
        })

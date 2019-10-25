treeview-check
    loader(if='{ opts.loader }')
    treenodes-check(if='{ !opts.loader }', nodes='{ nodes }', handlers='{ opts.handlers }', treeview='{ this }',
    label-field='{ labelField }', children-field='{ childrenField }', dblclick='{ opts.dblclick }')
        #{'yield'}(to='before')
            #{'yield'}(from='before')
        #{'yield'}(to='after')
            #{'yield'}(from='after')

    script(type='text/babel').
        var self = this

        self.nodes = []
        self.labelField = opts.labelField || 'label'
        self.childrenField = opts.childrenField || 'children'
        self.descendants = opts.descendants || undefined

        self.toggleChildren = (node, value) => {
            if (node[self.childrenField] && node[self.childrenField] instanceof Array) {
                node[self.childrenField].forEach(item => {
                    item.__selected__ = value
                    self.toggleChildren(item, value)
                })
            }
        }

        self.toggleParent = item => {
            if (item.__parent__) {
                let parent = item.__parent__
                if (parent instanceof Object && !(parent instanceof Array)) {
                    let selected = parent[self.childrenField].map(i => i.__selected__).indexOf(false) <= -1
                    parent.__selected__ = selected
                    self.toggleParent(parent)
                }
            }
        }

        self.deselectAll = (nodes = self.nodes) => {
            if (nodes instanceof Array) {
                nodes.forEach(item => {
                    item.__selected__ = false
                    if (item[self.childrenField])
                        self.deselectAll(item[self.childrenField])
                })
            }
        }

        self.getSelectedNodes = (nodes = self.nodes) => {
            let result = []
            if (nodes instanceof Array) {
                nodes.forEach(item => {
                    if (item.__selected__)
                        result.push(item)
                    if (item[self.childrenField]) {
                        let childResult = self.getSelectedNodes(item[self.childrenField])
                        result = [...result, ...childResult]
                    }
                })
                return result
            }
            return []
        }

        self.removeNodes = (nodes = self.nodes) => {
            let result = []
            if (nodes instanceof Array) {
                nodes.forEach(item => {
                    if (item.__selected__) {
                        nodes.splice(nodes.indexOf(item), 1);
                        self.removeNodes(nodes)
                        return
                    }
                    if (item[self.childrenField]) {
                        self.removeNodes(item[self.childrenField])
                    }
                })
            }
        }

        self.setNodes = (nodesList, childsList = false) => {
            if(self.nodes.length == 0){
                self.update()
            }
            if(childsList == false){
                self.nodes.forEach(node => {
                    if(nodesList.indexOf(node.id) > -1){
                        node.__selected__ = true
                        if(node.childs.length > 0){
                            node.childs = self.setNodes(nodesList, node.childs);
                        }
                    }
                    if(node.childs.length > 0){
                        node.childs = self.setNodes(nodesList, node.childs);
                    }
                })
            } else {
                childsList.forEach(node => {
                    if(nodesList.indexOf(node.id) > -1){
                        node.__selected__ = true
                    }
                    if(node.childs.length > 0){
                        node.childs = self.setNodes(nodesList, node.childs);
                    }
                })
                return childsList
            }
        }

        function setParentLinks(nodes, parent = self.nodes) {
            if (nodes instanceof Array) {
                nodes.forEach(item => {
                    Object.defineProperty(item, '__parent__', {
                        writable: true,
                        configurable: true,
                        enumerable: false,
                        value: parent
                    })
                    if (typeof(item) === 'object' && item[self.childrenField])
                        setParentLinks(item[self.childrenField], item)
                })
            }
        }

        self.on('update', () => {
            self.labelField = opts.labelField || 'label'
            self.childrenField = opts.childrenField || 'children'
            self.descendants = opts.descendants || undefined

            if (self.nodes !== opts.nodes) {
                self.nodes = opts.nodes || []
                setParentLinks(self.nodes)
            }
        })



treenodes-check
    ul(each='{ nodes }')
        li
            div(class='treenode', title='{ title }', ondblclick='{ dblclick }')
                span(class='icon { this[parent.childrenField].length ? expanded ? css.open  : css.closed : css.leaf }', onclick='{ toggleExpand }')
                #{'yield'}(from='before')
                input(type='checkbox', onclick='{ select }', checked='{ __selected__ ? true : false }')
                | &nbsp;
                span(class='{ this[parent.childrenField].length ? "" : "leaf" }') { this[parent.labelField] }
                #{'yield'}(from='after')
            treenodes-check(nodes='{ this[parent.childrenField] }', dblclick='{ dblclick }', handler='{ parent.handler }', css='{ parent.css }', if='{ expanded }',
            handlers='{ handlers }', treeview='{ treeview }', label-field='{ labelField }', children-field='{ childrenField }')
                #{'yield'}(to='before')
                    #{'yield'}(from='before')
                #{'yield'}(to='after')
                    #{'yield'}(from='after')






    style(scoped).
        ul {
            list-style: none;
            padding-left: 2em;
            margin: 0.25em 0;
        }
        li {
            cursor: pointer;
            margin-top:0.3em;
        }
        .icon {
            width: 1.1em;
        }

        .treenode.selected {
            background-color: #d9edf7;
        }

    script(type='text/babel').
        var self = this

        self.treeview = opts.treeview
        self.labelField = opts.labelField || 'label'
        self.childrenField = opts.childrenField || 'children'

        self.nodes = opts.nodes || []
        //self.nodes.map(n => {
        //    n.children = n.children || []
        //    //n.__selected__ = false
        //})

        var doubleClick = opts.dblclick || function (e) {}

        self.on('update', () => {
            self.title = opts.title
            self.css = opts.css  || {open: 'fa fa-fw fa-caret-down', closed: 'fa fa-fw fa-caret-right' , leaf: 'fa fa-fw'}
            self.nodes = opts.nodes || []
            self.handlers = opts.handlers || {}
            self.labelField = opts.labelField || 'label'
            self.childrenField = opts.childrenField || 'children'
        })

        self.dblclick = e => {
            doubleClick(e)
        }

        self.toggleExpand = e => {
            e.stopPropagation()
            e.item.expanded = !e.item.expanded
        }

        self.select = e => {
            e.item.__selected__ = !e.item.__selected__
            if (!e.ctrlKey) {
                self.treeview.toggleChildren(e.item, e.item.__selected__)
                if (self.treeview.descendants) {
                    self.treeview.toggleParent(e.item)
                    self.treeview.update()
                }
            } else {
                //self.treeview.deselectAll()
                if (self.treeview.descendants) {
                    self.treeview.toggleChildren(e.item, e.item.__selected__)
                }
                self.treeview.update()
            }


            let count = self.treeview.getSelectedNodes().length
            self.treeview.trigger('nodeselect', e.item, count)
        }

        self.stopPropagation = function (e) {
            e.stopPropagation()
        }
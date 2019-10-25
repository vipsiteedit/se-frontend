

filters-select-modal
    bs-modal
        #{'yield'}(to="title")
            .h4.modal-title Фильтры
        #{'yield'}(to="body")
            catalog(object='Filter', filters='{ parent.filters }',cols='{ parent.cols }', search='true', reload='true', disable-col-select='true', dblclick='{ parent.opts.submit.bind(this) }')
                #{'yield'}(to='body')
                    datatable-cell(name='id') { row.id }
                    datatable-cell(name='name') { row.name }
                    datatable-cell(name='code') { row.code }
        #{'yield'}(to='footer')
            button(onclick='{ modalHide }', type='button', class='btn btn-default btn-embossed') Закрыть
            button(onclick='{ parent.opts.submit.bind(this) }', type='button', class='btn btn-primary btn-embossed') Выбрать

    script(type='text/babel').
        var self = this

        self.cols = [
            {name: 'id', value: '#'},
            {name: 'name', value: 'Наименование'},
            {name: 'code', value: 'Код'},
        ]
        var value = opts.idGroup || 0
        self.filters = [{field: 'idGroup', sign: 'IN', value}]
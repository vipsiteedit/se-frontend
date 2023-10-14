persons-company-list-modal
    bs-modal
        #{'yield'}(to="title")
            .h4.modal-title Компании
        #{'yield'}(to="body")
            catalog(name='companies', object='Company', cols='{ parent.cols }', search='true', reload='false', 
            dblclick='{ parent.opts.submit.bind(this) }', disable-col-select='1')
                #{'yield'}(to='body')
                    datatable-cell(name='id') { row.id }
                    datatable-cell(name='name') { row.name }
        #{'yield'}(to='footer')
            button(onclick='{ modalHide }', type='button', class='btn btn-default btn-embossed') Закрыть
            button(onclick='{ parent.opts.submit.bind(this) }', type='button', class='btn btn-primary btn-embossed') Выбрать

    script(type='text/babel').
        var self = this

        self.cols = [
            {name: 'id', value: '#'},
            {name: 'name', value: 'Наименование'},
        ]
        
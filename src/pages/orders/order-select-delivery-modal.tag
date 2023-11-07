order-select-delivery-modal
    bs-modal
        #{'yield'}(to="title")
            .h4.modal-title Изменить статус доставки
        #{'yield'}(to="body")
            form(onchange='{ change }', onkeyup='{ change }')
                .form-group
                    label.control-label Статус доставки
                    select.form-control(name='deliveryStatus')
                        option(each='{ key, value in deliveryItems }', value='{ key }',
                        selected='{ key == item.deliveryStatus }', no-reorder) { value }
        #{'yield'}(to='footer')
            button(onclick='{ modalHide }', type='button', class='btn btn-default btn-embossed') Закрыть
            button(onclick='{ parent.opts.submit }', type='button', class='btn btn-primary btn-embossed') Сохранить

    script(type='text/babel').
        var self = this

        self.on('mount', () => {
            let modal = self.tags['bs-modal']

            modal.item = {}
            modal.item.deliveryStatus = 'N';
            //modal.mixin('validation')
            modal.mixin('change')

            modal.deliveryItems = {
                Y: 'Доставлен', N: 'Не доставлен', M: 'В работе', P: 'Отправлен'
            }


            //modal.rules = {
            //    name: 'empty'
            //}

            //modal.afterChange = e => {
            //    modal.error = modal.validation.validate(modal.item, modal.rules, e.target.name)
            //}
        })
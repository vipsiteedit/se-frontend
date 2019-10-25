checkbox-list-inline
    label.form-check-inline(each='{ items }')
        input.form-check-input(data-id='{ id }', type='checkbox', checked='{ isChecked }', onclick='{ click }')
        | &nbsp { name } &nbsp&nbsp

    script(type='text/babel').
        var self = this

        self.click = e => {
            let id = e.target.dataset.id
            let isChecked = e.target.checked
            self.items.forEach(item => {
                if (item.id == id)
                    item.isChecked = isChecked
        })

        var event = document.createEvent('Event')
            event.initEvent('change', true, true)
            self.root.dispatchEvent(event)
        }

        self.on('update', () => {
            self.items = opts.items
        })


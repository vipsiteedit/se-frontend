import-products-modal
    bs-modal
        #{'yield'}(to="title")
            .h4.modal-title Импорт (Шаг 1 из 2)
        #{'yield'}(to="body")
            loader(text='Импорт', indeterminate='true', if='{ loader }')
            form(onchange='{ change }', onkeyup='{ change }')
                .form-group(class='{ has-error: error.filename }')
                    textarea.form-control(
                        name='importtext',
                        placeholder='Скопируйте в буфер обмена текст импорта и вставьте сюда',
                        row="100"
                    )
                .row
                    .col-md-6.col-xs-12
                        .form-group
                            label.control-label Разделитель столбцов
                            select.form-control(id='delimId', name='delimiter', value='{ item.delimiter }')
                                option(
                                    each='{ i in delimiters }', value='{ i.name }',
                                    selected='{ i.name == parent.item.delimiter }', no-reorder
                                ) { i.title }

                    .col-md-6.col-xs-12
                        .form-group
                            label.control-label Пропустить строк
                            input.form-control(name='skip', type='number', min='0', step='1', value='{ item.skip }')

                    .help-block { error.filename }

            div(id="terminalImport", style='width: 100%; margin-top: 20px; color: #a94442')
        #{'yield'}(to='footer')
            button(onclick='{ modalHide }', type='button', class='btn btn-default btn-embossed', disabled='{ cannotBeClosed }') Закрыть
            button(onclick='{ parent.submit }', type='button', class='btn btn-primary btn-embossed', disabled='{ cannotBeClosed }') Продолжить


    script(type='text/babel').
        var self = this
        self.loader = true

        // ВКЛ
        self.on('mount', () => {
            let modal = self.tags['bs-modal']

            // нужно получать профили из браузера
            var profiles = JSON.parse(localStorage.getItem("profiles")) // отсутствуют - null

            // поля селектора профиля загрузки,
            // значение при отсутствии записей в браузере
            modal.uploadProfiles = [
                {name: 'profile1',  title: 'Профиль 1'}
            ]

            // загружаем профили из браузера
            if (profiles == null) {
                var profiles = {}
            } else {
                modal.uploadProfiles = []
                for (var key in profiles) {
                    if(key != 'groupNow') {
                        let profileUnit = {name: key,  title: profiles[key]['title']}
                        modal.uploadProfiles.push(profileUnit)
                    }
                }
            }

            /*// ... кодировки
            modal.encodings = [
                {name: 'utf-8',         title: 'UTF-8'},
                {name: 'windows-1251',  title: 'Windows-1251'}
            ]*/

            // ... разделителителя столбцов
            modal.delimiters = [
                {name: 'auto',  title: 'Автоопределение'},
                {name: ';',     title: 'Точка с запятой'},
                {name: ',',     title: 'Запятая'},
                {name: '\t',    title: 'Табуляция'}
            ]


            // значния по умолчанию
            modal.error = false
            modal.mixin('validation')
            modal.mixin('change')

            // получаем настройки последнего профиля или по умолчанию
            if(Object.keys(profiles).length != 0) {

                var uploadProfileValue = profiles['groupNow']
                if (profiles != undefined && uploadProfileValue != undefined) {

                    if( profiles[uploadProfileValue]['title'] != undefined) {
                        var titleValue = profiles[uploadProfileValue]['title']
                    } else {var titleValue = undefined}

                    if(profiles[uploadProfileValue]['delimiter'] != undefined) {
                        var delimiterValue = profiles[uploadProfileValue]['delimiter']
                    } else {var delimiterValue = modal.delimiters[0]['name']}

                    if(profiles[uploadProfileValue]['keyField'] != undefined) {
                        var keyFieldValue = profiles[uploadProfileValue]['keyField']
                    } else {var keyFieldValue = modal.keyFields[0]['name']}

                    if(profiles[uploadProfileValue]['limiterField'] != undefined) {
                        var limiterFieldValue = profiles[uploadProfileValue]['limiterField']
                    } else {var limiterFieldValue = '"'}

                    if(profiles[uploadProfileValue]['skip'] != undefined) {
                        var skipValue = profiles[uploadProfileValue]['skip']
                    } else {var skipValue = 1}

                    if(profiles[uploadProfileValue]['margins'] != undefined) {
                        var marginsValue = profiles[uploadProfileValue]['margins']
                    } else {var marginsValue = undefined}
                } else {
                    var uploadProfileValue = modal.uploadProfiles[0]['name']
                    var titleValue = modal.uploadProfiles[0]['title']
                    var delimiterValue = modal.delimiters[0]['name']
                    var keyFieldValue = modal.keyFields[0]['name']
                    var limiterFieldValue = '"'
                    var skipValue = 1
                    var marginsValue = undefined
                }
            } else {
                var uploadProfileValue = modal.uploadProfiles[0]['name']
                var titleValue = modal.uploadProfiles[0]['title']
                var delimiterValue = modal.delimiters[0]['name']
                var keyFieldValue = modal.keyFields[0]['name']
                var limiterFieldValue = '"'
                var skipValue = 1
                var marginsValue = undefined
            }

            modal.item = {
                importtext      : '',
                reset         : false,

                uploadProfile : uploadProfileValue,
                title         : titleValue,
                delimiter     : delimiterValue,
                keyField      : keyFieldValue,
                limiterField  : limiterFieldValue,
                skip          : skipValue,

                margins       : marginsValue
            }

            modal.rules = {
                filename: {
                    required: true,
                    rules:[{
                        type: 'url',
                        prompt: 'Выберите файл или введите правильную ссылку',
                    }]
                }
            }

            modal.loader = false


            // после изменения
            modal.afterChange = e => {
                if (modal.file.files && !modal.file.files.length) {
                    let name = e.target.name
                    delete modal.error[name]
                    modal.error = {...modal.error, ...modal.validation.validate(modal.item, modal.rules, name)}
                }

                if (modal.file.files && modal.file.files.length)
                    modal.error = false

                if (modal.item && modal.item.type == 0)
                    modal.item.reset = false

                delete modal.item.file
            }
        })
        
        // ОТПРАВИТЬ
        self.submit = () => {
            let modal = self.tags['bs-modal']
            let formData = new FormData()
            let target = modal.file
            modal.loader = true

            //formData.append('type', modal.item.type)
            //formData.append('reset', modal.item.reset)
            formData.append('prepare', true)

            if (target.files.length) {
                for (var i = 0; i < target.files.length; i++) {
                   formData.append('file' + i, target.files[i], target.files[i].name)
                }
            } else {
                formData.append('url', modal.item.filename)
                modal.error = modal.validation.validate(modal.item, modal.rules)
                if (modal.error) return
            }
            // прикрепляем к отправке параметры
            var idGroup = 0
            if (modal.item.inGroup) {
                idGroup = opts.idGroup
            }
            formData.append('uploadProfile', modal.item.uploadProfile)
            /*formData.append('encoding', modal.item.encoding)*/
            formData.append('delimiter', modal.item.delimiter)
            formData.append('keyField', modal.item.keyField)
            formData.append('limiterField', modal.item.limiterField)
            formData.append('skip', parseInt(modal.item.skip))
            formData.append('idGroup', idGroup)

            // получаем настройки по профилям из браузера
            var profiles = JSON.parse(localStorage.getItem("profiles")) // отсутствуют - null

            // если настройки не совподают или их нет - добаить новый профиль
            // (если нет параметра - перезаписывается в профиль)
            var create = true
            if (profiles == null) {
                var profiles = {}
            } else if(Object.keys(profiles).length == 1) {
                var create = false
            } else {
                for (var key in profiles) {
                    if (
                        modal.item.delimiter    == profiles[key]['delimiter'] &&
                        modal.item.keyField     == profiles[key]['keyField'] &&
                        modal.item.limiterField == profiles[key]['limiterField']
                        //- modal.item.skip         == profiles[key]['skip']  // отступ менятеся внутри профиля
                    ) {
                        var create = false
                        break
                    }
                }
            }

            if (create == true) {
                // генерируем новый профиль

                // получаем список имен профилей - генерируем новое название
                var numProfiles = 1
                var stop = false
                while(stop == false) {
                    var array_in_presence = false

                    // проверяем наличие имени в списке
                    for (var key in profiles) {
                        if (`profile${numProfiles}` == key) {
                            array_in_presence = true
                            break
                        }
                    }

                    // нет - присваивае к newNameProfile, останавливаем перебор
                    // есть - поднимаем номер, продолжаем перебор
                    if(array_in_presence == false) {
                        var newNameProfile  = `profile${numProfiles}`
                        var newTitleProfile = `Профиль ${numProfiles}`
                        stop = true
                    } else numProfiles += 1

                }
            } else {
                // редактируем старый профиль
                var newNameProfile  = modal.item.uploadProfile
                var newTitleProfile = modal.item.title
            }

            // собираем данные
            let newProfileSettings = {
                'title'              : newTitleProfile,
                'delimiter'          : modal.item.delimiter,
                'keyField'           : modal.item.keyField,
                'limiterField'       : modal.item.limiterField,
                'skip'               : parseInt(modal.item.skip),

                'margins'            : modal.item.margins
            }

            // добавляем в массив и возвращаем браузеру
            profiles[newNameProfile] = newProfileSettings
            profiles['groupNow'] = newNameProfile

            var serialProfiles = JSON.stringify(profiles)
            localStorage.setItem('profiles', serialProfiles)

            modal.uploadProfiles = []
            for (var key in profiles) {
                if(key != 'groupNow') {
                    let profileUnit = {name: key,  title: profiles[key]['title']}
                    modal.uploadProfiles.push(profileUnit)
                }
            }
            modal.update()


            API.upload({
                object: 'Product',
                data: formData,
                success: function(response) {
                    console.log(response)
                    if (response.errors=='') {
                        let dataI = response;
                        dataI.filename = modal.item.filename
                        dataI.uploadProfile = modal.item.uploadProfile
                        localStorage.setItem('shop24_import_products', JSON.stringify(dataI))
                        var items = JSON.parse(localStorage.getItem('shop24_import_products') || '{}')
                        modal.modalHide()
                        observable.trigger('products-imports')
                    }

                    var elemT = document.getElementById("terminalImport")
                    elemT.innerHTML = response.errors
                },
                complete: function() {
                    modal.loader = false
                    modal.cannotBeClosed = false
                    modal.update()
                }
            })
        }

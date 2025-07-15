///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, ООО ДНС Технологии
// SDMS (Software Development Management System) — это корпоративная система учета разработки и управления проектами 
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии General Public License (GNU GPL v3)
// Текст лицензии доступен по ссылке:
// https://www.gnu.org/licenses/gpl-3.0.html
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Если Сервер ИЛИ ТолстыйКлиентОбычноеПриложение ИЛИ ВнешнееСоединение Тогда
	
#Область ПрограммныйИнтерфейс

// Добавляет электронное письмо в очередь на отправку.
//
// Параметры:
//  Адрес - Строка, Массив - строка с аресом электронной почты получателя или массив таких строк.
//  Тема - Строка - тема сообщения.
//  Текст - Строка - тело сообщения.
//  Важность - ПеречислениеСсылка.ВажностьСообщения - важность письма (по умолчанию Обычная)
//  Отправлено - Булево - письмо уже отправлено, запись добавляется для логирования
//
Процедура Добавить(Знач Адрес, Знач Тема, Знач Текст, Знач Важность = Неопределено,	Знач Отправлено = Ложь) Экспорт
	
	ТекущаяДата = ТекущаяДатаСеанса();
	
	Если Важность = Неопределено Тогда
		Важность = Перечисления.ВажностьСообщения.Обычная;
	КонецЕсли;
	
	Если ТипЗнч(Адрес) = Тип("Строка") Тогда
		МассивАдресов = Новый Массив;
		МассивАдресов.Добавить(Адрес);
	Иначе
		МассивАдресов = Адрес;
	КонецЕсли;
	
	Для Каждого ЭлектроннаяПочта Из МассивАдресов Цикл
		ИдентификаторЗаписи = Новый УникальныйИдентификатор;
		
		НаборЗаписей = РегистрыСведений.ОчередьОтправкиЭлектронныхПисем.СоздатьНаборЗаписей();
		НаборЗаписей.Отбор.УникальныйИдентификатор.Установить(ИдентификаторЗаписи);
		
		НоваяЗапись = НаборЗаписей.Добавить();
		НоваяЗапись.УникальныйИдентификатор = ИдентификаторЗаписи;
		НоваяЗапись.Адрес 					= ЭлектроннаяПочта;
		НоваяЗапись.Тема       				= Тема;
		НоваяЗапись.Текст      				= Текст;
		НоваяЗапись.ДатаСоздания 			= ТекущаяДата;
		НоваяЗапись.Важность	 				= Важность;
		
		Если Отправлено Тогда
			НоваяЗапись.Отправлено = Истина;
			НоваяЗапись.ДатаОтправления = ТекущаяДата;
		КонецЕсли;
		
		НаборЗаписей.Записать();
	КонецЦикла;
	
КонецПроцедуры

// Возвращает строковое представление события для отображения в журнале регистрации
//
Функция ИмяСобытияДляЖурналаРегистрации() Экспорт
	
	Возврат "Отправка электронных писем";
	
КонецФункции

Процедура Отправить() Экспорт
	
	ИмяСобытия = ИмяСобытияДляЖурналаРегистрации();
	
	// Проверим очередь электронных писем. Если она пустая, то не за чем дальше
	// выполнять метод.
	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ
	|	ОчередьОтправкиЭлектронныхПисем.УникальныйИдентификатор КАК УникальныйИдентификатор,
	|	ОчередьОтправкиЭлектронныхПисем.Адрес КАК Адрес,
	|	ОчередьОтправкиЭлектронныхПисем.Тема КАК Тема,
	|	ОчередьОтправкиЭлектронныхПисем.Текст КАК Текст,
	|	ОчередьОтправкиЭлектронныхПисем.КоличествоПопыток КАК КоличествоПопыток,
	|	ОчередьОтправкиЭлектронныхПисем.ДатаСоздания КАК ДатаСоздания,
	|	ОчередьОтправкиЭлектронныхПисем.Отправлено КАК Отправлено,
	|	ОчередьОтправкиЭлектронныхПисем.ДатаОтправления КАК ДатаОтправления,
	|	"""" КАК Комментарий,
	|	ОчередьОтправкиЭлектронныхПисем.Важность КАК Важность
	|ИЗ
	|	РегистрСведений.ОчередьОтправкиЭлектронныхПисем КАК ОчередьОтправкиЭлектронныхПисем
	|ГДЕ
	|	НЕ ОчередьОтправкиЭлектронныхПисем.Отправлено
	|	И ОчередьОтправкиЭлектронныхПисем.КоличествоПопыток < 5
	|
	|УПОРЯДОЧИТЬ ПО
	|	ДатаСоздания";
	
	ТаблицаИсходящихПисем = Запрос.Выполнить().Выгрузить();
	
	КоличествоПисем = ТаблицаИсходящихПисем.Количество();
	Если КоличествоПисем = 0 Тогда
		ЗаписьЖурналаРегистрации(ИмяСобытия, УровеньЖурналаРегистрации.Информация, , ,
			"Очередь электронных писем на отправку пустая.");
		Возврат;
	Иначе
		ЗаписьЖурналаРегистрации(ИмяСобытия, УровеньЖурналаРегистрации.Информация, , ,
			СтрШаблон("Количество электронных писем в очереди на отправку: %1.", Строка(КоличествоПисем)));
	КонецЕсли;
	
	// Получим профиль почты
	ДанныеПочты = Справочники.УчетныеЗаписиЭлектроннойПочты.СвойстваСлужебногоЯщикаДляОтправкиПисем();
	
	Если НЕ ДанныеПочты.ПрофильЗаполнен Тогда
		ЗаписьЖурналаРегистрации(ИмяСобытия, УровеньЖурналаРегистрации.Ошибка, , ,
			"В справочнике ""Учетные записи электронной почты"" не найдена учетная запись для отправки электронной почты.");
		Возврат;
	КонецЕсли;
		
	// Пробуем подключиться к почтовому серверу
	Почта = ПолучитьСоединениеСПочтовымСервером(ДанныеПочты.ПочтовыйПрофиль);
	
	Если Почта = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	ДиректорияФайлов = ВыделитьДиректориюДляФайловРассылки();
	
	// Получение шаблонов
	ШаблоныПисьма = ШаблоныЭлектронногоПисьма(ДиректорияФайлов);
	
	КоличествоОшибокПодряд = 0;
	ПодстрокаЗаменыДляВебКлиента = WebОкружениеВызовСервера.АдресПубликацииИнформационнойБазы();
	
	СтруктураПисьма = ШаблоныПисьма.СтруктураЭлектронногоПисьма;
	
	ФайлыКартинок = Новый Соответствие;
	
	Для Каждого СтрокаТаблицы Из ТаблицаИсходящихПисем Цикл
		Если КоличествоОшибокПодряд > 7 Тогда
			ЗаписьЖурналаРегистрации(ИмяСобытия, УровеньЖурналаРегистрации.Ошибка, , , 
				"Превышено количество повторяющихся ошибок отправки почты. Операция прервана.");
			Прервать;
		КонецЕсли;	
		
		// Создаем почтовое сообщение
		Сообщение = Новый ИнтернетПочтовоеСообщение;
		Сообщение.Кодировка = КодировкаТекста.UTF8;
		Сообщение.ИмяОтправителя = ДанныеПочты.Отправитель.Имя;
		Сообщение.Отправитель = ДанныеПочты.Отправитель.Адрес;
		
		ТекстСообщения = СтрЗаменить(СтруктураПисьма, "<!-- content -->", СтрокаТаблицы.Текст);
		ТекстСообщения = СтрЗаменить(ТекстСообщения, "<!-- sdms_link_prefix -->", ПодстрокаЗаменыДляВебКлиента);
		
		ОбработатьШаблоныДляКартинокПисьма(ДиректорияФайлов, ИмяСобытия, ТекстСообщения, ФайлыКартинок);
		
		// TODO: Когда понадобится, дописать алгоритм прикрепления вложений
		СтрокаТаблицы.КоличествоПопыток = СтрокаТаблицы.КоличествоПопыток + 1;
		
		Сообщение.Тема = СтрокаТаблицы.Тема;
		
		Сообщение.Тексты.Очистить();
		Сообщение.Тексты.Добавить(ТекстСообщения, ТипТекстаПочтовогоСообщения.HTML);
		
		Попытка
			Сообщение.ОбработатьТексты();
			ТекстОбработан = Истина;
		Исключение
			ТекстОбработан = Ложь;
			ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
			ТекстОшибки = СтрШаблон("Ошибка при обработки текста письма получателю %1 по причине: %2.", 
				СтрокаТаблицы.Адрес, ТекстОшибки);
			ЗаписьЖурналаРегистрации(ИмяСобытия, УровеньЖурналаРегистрации.Ошибка, , , ТекстОшибки);
		КонецПопытки;
			
		Если НЕ ТекстОбработан Тогда
			Продолжить;
		КонецЕсли;
		
		Если СтрокаТаблицы.Важность = Перечисления.ВажностьСообщения.Наивысшая Тогда
			Сообщение.Важность = ВажностьИнтернетПочтовогоСообщения.Наивысшая;
		ИначеЕсли СтрокаТаблицы.Важность = Перечисления.ВажностьСообщения.Высокая Тогда
			Сообщение.Важность = ВажностьИнтернетПочтовогоСообщения.Высокая;
		ИначеЕсли СтрокаТаблицы.Важность = Перечисления.ВажностьСообщения.Обычная Тогда
			Сообщение.Важность = ВажностьИнтернетПочтовогоСообщения.Обычная;
		ИначеЕсли СтрокаТаблицы.Важность = Перечисления.ВажностьСообщения.Низкая Тогда
			Сообщение.Важность = ВажностьИнтернетПочтовогоСообщения.Низкая;
		ИначеЕсли СтрокаТаблицы.Важность = Перечисления.ВажностьСообщения.Наименьшая Тогда
			Сообщение.Важность = ВажностьИнтернетПочтовогоСообщения.Наименьшая;
		КонецЕсли;
		
		Сообщение.Получатели.Очистить();
		Сообщение.Получатели.Добавить(СтрокаТаблицы.Адрес);

		Попытка
			Почта.Послать(Сообщение);
			СтрокаТаблицы.Отправлено = Истина;
			СтрокаТаблицы.ДатаОтправления = ТекущаяДатаСеанса();
			КоличествоОшибокПодряд = 0;
		Исключение
			СтрокаТаблицы.Отправлено  = Ложь;
			СтрокаТаблицы.Комментарий = ОписаниеОшибки();
			
			ЗаписьЖурналаРегистрации(ИмяСобытия, УровеньЖурналаРегистрации.Ошибка, , , 
				СтрШаблон("Ошибка при отправке письма получателю <%1> по причине: %2.", 
				СтрокаТаблицы.Адрес, ОписаниеОшибки()));
			
			КоличествоОшибокПодряд = КоличествоОшибокПодряд + 1;
		КонецПопытки;
		
		Сообщение.Вложения.Очистить();
		
	КонецЦикла;
	
	ОтключитьСоединениеСПочтовымСервером(Почта);
	
	ОчиститьВыделеннуюДиректориюФайловПисьма(ДиректорияФайлов, ИмяСобытия);
	
	// Обновим состояния тех писем, которые были отправлены
	БлокировкаДанных = Новый БлокировкаДанных;
	ЭлементБлокировки = БлокировкаДанных.Добавить("РегистрСведений.ОчередьОтправкиЭлектронныхПисем");
	ЭлементБлокировки.ИсточникДанных = ТаблицаИсходящихПисем;
	ЭлементБлокировки.ИспользоватьИзИсточникаДанных("УникальныйИдентификатор", "УникальныйИдентификатор");	
	
	НачатьТранзакцию();
	
	Попытка
		БлокировкаДанных.Заблокировать();
		
		Для Каждого СтрокаТаблицы Из ТаблицаИсходящихПисем Цикл
			НаборЗаписей = РегистрыСведений.ОчередьОтправкиЭлектронныхПисем.СоздатьНаборЗаписей();
			НаборЗаписей.Отбор.УникальныйИдентификатор.Установить(СтрокаТаблицы.УникальныйИдентификатор);
			НаборЗаписей.Прочитать();
			
			Если НаборЗаписей.Количество() = 0 Тогда
				Продолжить;
			КонецЕсли;
			
			ЗаполнитьЗначенияСвойств(НаборЗаписей[0], СтрокаТаблицы, 
				"КоличествоПопыток, Отправлено, ДатаОтправления, Комментарий");
				
			НаборЗаписей.Записать();
		КонецЦикла;
		
		ЗафиксироватьТранзакцию();
	Исключение
		ОтменитьТранзакцию();
		ЗаписьЖурналаРегистрации(ИмяСобытия, УровеньЖурналаРегистрации.Ошибка, , , 
			СтрШаблон("Ошибка обновления состояния очереди отправки электронных писем: %1.", 
			ОписаниеОшибки()));
	КонецПопытки;
	
КонецПроцедуры

// Возвращает шаблоны для формирования письма при изменении реквизитов
// 
// Возвращаемое значение:
// Результат - Стркутра - Шаблон
//
Функция ШаблоныИзмененныхРеквизитов() Экспорт
	
	Результат = Новый Структура;
	
	// Блок для вывода изменения значения реквизита
	// Параметры:
	//	<!-- attribute -->	 - название реквизита
	//	<!-- values -->		 - старое (если есть) и новое значение реквизита
	Изменение = 
	"<tr style = ""height: 25px; word-break: break-all; word-wrap: break-word;"">
	|	<td style=""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; line-height: 1.3; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; padding-left:15px; width: 200px; min-width: 200px; max-width: 200px;""><!-- attribute --></td>
	|	<td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; line-height: 1.3; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left;""><!-- values --></td>
	|</tr>";
	
	Результат.Вставить("Изменение", Изменение);
	
	// Блок для вывода изменений в строке табличной части
	// Параметры:
	//	<!-- title -->	 		- название табличной части
	//	<!-- values -->		 - изменения табличной части
	ИзменениеСтроки = 
	"<tr style = ""height: 25px; word-break: break-all; word-wrap: break-word;"">
	|	<td colspan=2 style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; line-height: 1.3; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; padding-left:15px;""><!-- title --><p style=""padding-left: 10px; margin: 0px""><!-- values --></p></td>
	|</tr>";
	
	Результат.Вставить("ИзменениеСтроки", ИзменениеСтроки);
	
	// Блок для вывода нового значения
	// Параметры:
	//	<!-- value -->	 - новое значение реквизита
	Результат.Вставить("НовоеЗначение", "<span style=""word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; background: #e3fee4;""><!-- value --></span>");
	
	// Блок для вывода предыдущего значения
	// Параметры:
	//	<!-- value -->	 - предыдущее значение реквизита
	Результат.Вставить("СтароеЗначение", "<span style=""word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; text-decoration: line-through; background: #ffebe6;""><!-- value --></span>  ");
	
	ТекстСообщения = 
	"<tr style = 'height: 25px; word-break: break-all; word-wrap: break-word;'>
	| <td style='font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; line-height: 1.3; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; padding-left:15px; width: 200px; min-width: 200px; max-width: 200px;'>
	|<span> Было изменено %1 <a href = '%2'> Просмотр изменений</a></span>
	| </td>
	|</tr>";

	Результат.Вставить("ИзменениеОписания", ТекстСообщения);

	Возврат Результат;
	
КонецФункции

// Создаёт каталог для хранения временных файлов рассылки для последующего удаления. 
// 
// Возвращаемое значение:
// ДиректорияФайлов - Строка - путь хранения файлов
//
Функция ВыделитьДиректориюДляФайловРассылки() Экспорт
	
	КаталогВременныхФайлов = ПовторноеИспользованиеВызовСервера.ПолучитьКаталогВременныхФайлов();
	УникальноеИмя = СтрЗаменить(Строка(Новый УникальныйИдентификатор), "-", "");
	ДиректорияФайлов = КаталогВременныхФайлов + РаботаСФайламиКлиентСервер.ДобавитьРазделительПути(УникальноеИмя);
	СоздатьКаталог(ДиректорияФайлов);
	
	Возврат ДиректорияФайлов;
	
КонецФункции

Процедура ОбработатьШаблоныДляКартинокПисьма(Знач ДиректорияФайлов, Знач ИмяСобытия, ТекстСообщения, ФайлыКартинок = Неопределено) Экспорт
	
	// Осуществляет поиск в тексте сообщения шаблонов картинок формата <!-- img_name_ИмяКартинкиВИБ -->
	// Получает их имя, сохраняет в директорию файлов и заменяет в тексте 
	
	Если ФайлыКартинок = Неопределено Тогда
		ФайлыКартинок = Новый Соответствие;
	КонецЕсли;
	
	ПоискКартинок = СтрНайтиВсеПоРегулярномуВыражению(ТекстСообщения, "<!-- img_name_[\S]+? -->");
	
	НачалоЗначенияШаблона = 1 + СтрДлина("<!-- img_name_");
	ВсегоСимволовШаблона = СтрДлина("<!-- img_name_ -->");
	
	ОбработанныеКартинки = Новый Соответствие;
	
	Для Каждого РезультатПоиска Из ПоискКартинок Цикл
		
		ШаблонКартинки = РезультатПоиска.Значение;
		
		Если ОбработанныеКартинки.Получить(ШаблонКартинки) = Истина Тогда
			Продолжить;
		КонецЕсли;
		
		ИмяКартинкиВБиблиотеке = Сред(ШаблонКартинки, НачалоЗначенияШаблона, РезультатПоиска.Длина - ВсегоСимволовШаблона);
		
		ИмяФайлаКартинки = ФайлыКартинок.Получить(ИмяКартинкиВБиблиотеке);
		
		Если ИмяФайлаКартинки = Неопределено Тогда
			Попытка
				ИмяФайлаКартинки = ДиректорияФайлов + РаботаСФайламиКлиентСервер.СоздатьУникальноеИмяФайла(".png");
				
				БиблиотекаКартинок[ИмяКартинкиВБиблиотеке].Записать(ИмяФайлаКартинки);
				
				ФайлыКартинок.Вставить(ИмяКартинкиВБиблиотеке, ИмяФайлаКартинки);
			Исключение
				ИмяФайлаКартинки = "";
				ЗаписьЖурналаРегистрации(ИмяСобытия, УровеньЖурналаРегистрации.Ошибка, , , 
					СтрШаблон("Не удалось сохранить картинку письма по причине: %1.", ОписаниеОшибки()));
			КонецПопытки;
			
		КонецЕсли;
		
		Если НЕ ПустаяСтрока(ИмяФайлаКартинки) Тогда
			ТекстСообщения = СтрЗаменить(ТекстСообщения, ШаблонКартинки, ИмяФайлаКартинки);
			ОбработанныеКартинки.Вставить(ШаблонКартинки, Истина);
		КонецЕсли;
		
	КонецЦикла;

КонецПроцедуры

// Удаляет созданный каталог для хранения временных файлов. 
// 
// Параметры:
// ДиректорияФайлов - Строка - путь хранения файлов
// ИмяСобытия - Строка - имя события для записи в журнал регистрации.
//
Процедура ОчиститьВыделеннуюДиректориюФайловПисьма(Знач ДиректорияФайлов, Знач ИмяСобытия) Экспорт
	
	Для Индекс = 0 По 10 Цикл
		Попытка
			УдалитьФайлы(ДиректорияФайлов);
			Прервать;
		Исключение
			Сообщение = ОписаниеОшибки();
			
			Если Найти(НРег(Сообщение), "ошибка совместного доступа") > 0 И Индекс < 10 Тогда
				
				// Приостановим выполнение для завершения работы с файлами.
				ОбщегоНазначения.Пауза(3);
				Продолжить;
			Иначе
				ЗаписьЖурналаРегистрации(ИмяСобытия, УровеньЖурналаРегистрации.Ошибка, , ,
					СтрШаблон("В процессе удаления временных файлов вложений произошла ошибка: %1", Сообщение));
				Возврат;
			КонецЕсли;
		КонецПопытки;
	КонецЦикла;
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

// Отключает соединение с почтовым сервером
//
// Параметры:
//  Почта - ИнтернетПочта - соединение с почтовым сервером
//
Процедура ОтключитьСоединениеСПочтовымСервером(Почта) Экспорт
	
	Если Почта <> Неопределено Тогда
		Попытка
			Почта.Отключиться();
		Исключение
			ЗаписьЖурналаРегистрации(ИмяСобытияДляЖурналаРегистрации(), УровеньЖурналаРегистрации.Ошибка, , , 
				СтрШаблон("При отключении от SMTP-сервера возникла ошибка: %1.", ОписаниеОшибки()));
		КонецПопытки;
	КонецЕсли;
	
КонецПроцедуры

// Осуществляет подключение к почтовому серверу
//
// Параметры:
//  ПочтовыйПрофиль - ИнтернетПочтовыйПрофиль - свойстви для соединения с сервером
// 
// Возвращаемое значение:
//  ИнтернетПочта - соединение или Неопределено, если не получилось
//
Функция ПолучитьСоединениеСПочтовымСервером(Знач ПочтовыйПрофиль) Экспорт
	
	// Пробуем подключиться к почтовому серверу
	Почта = Новый ИнтернетПочта;
	
	Попытка
		Почта.Подключиться(ПочтовыйПрофиль);
	Исключение
		ЗаписьЖурналаРегистрации(ИмяСобытияДляЖурналаРегистрации(), УровеньЖурналаРегистрации.Ошибка, , ,
			СтрШаблон("Не удалось подключиться к SMTP-серверу по причине: %1", ОписаниеОшибки()));
		Почта = Неопределено;
	КонецПопытки;
	
	Возврат Почта;
	
КонецФункции

// Возвращает шаблоны для формирования письма
// 
// Возвращаемое значение:
//   - Структура
//		* Разделитель16
//		* Разделитель24
//		* Разделитель16СЧертой
//		* ЛоготипSDMS
//		* ШаблонОбъекта
//		* Страница
//		* Подвал
//		* ЗаголовокСобытия
//		* ТаблицаИзменений
//		* Комментарий
//
Функция ШаблонСтраницы() Экспорт
		
	// Шаблон страницы
	// Параметры:
	//	<!-- content -->		  - содержимое письма
	//	<!-- sdms_link_prefix --> - ссылка на SDMS (в зависимости от настройки пользователя (web или тонкий клиент))
	//	<!-- current_year -->	  - текущий год
	//	<!-- sdms_logo -->		  - путь к картинке логотипа
	Страница = 
	"<!DOCTYPE HTML PUBLIC ""-//W3C//DTD HTML 4.01 Transitional//EN"" ""http://www.w3.org/TR/html4/loose.dtd"">
	|<html lang=""ru"">
	|<head>
	|<meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8"">
	|<title>Автоматическое уведомление - Система задач SDMS</title>
	|<style type=""text/css"">a,a:visited{color:#0052cc;text-decoration:none;}a:hover,a:active{color:#147dc2;}</style>
	|</head>
	|<body style=""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; text-align: left; line-height: 1.3;"">
	|<center>
	|<table>
	|<tr>
	|<td style=""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; line-height: 1.3; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; width: 580px; margin-top: 10px;"">
	|<table><tr><td style=""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; line-height: 16px; height: 16px;""></td></tr></table>
	|<table><tr><td style=""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; line-height: 1.3; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left;""><img src=""<!-- sdms_logo -->"" alt=""""></td></tr></table>
	|<table><tr><td style=""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; line-height: 16px; height: 16px;""></td></tr></table>
	|<!-- content -->
	|<table style=""width: 580px; margin-top: 10px;""><tr><td style=""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; line-height: 16px; height: 16px;""></td></tr></table>
	|<table style = ""width: 580px; margin-top: 10px;""><tr><td style=""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; font-size: 14px; line-height: 45px; vertical-align: bottom; text-align: center; border-top: 1px solid #eee;"">(C) <a href=""<!-- sdms_link_prefix -->"" style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; text-align: left; line-height: 1.3; text-decoration: none;"">SDMS</a> <!-- current_year --></td></tr></table>
	|</td>
	|</tr>
	|</table>
	|</center>
	|</body>
	|</html>";
	
	Возврат Страница;
	
КонецФункции

// Функция - Получить шаблон электронного письма
//
// Параметры:
//  ВставитьГиперссылкуОтписаться	 - Булево - Добавляет гиперссылку "Отписаться" в шаблон 
// 
// Возвращаемое значение:
// Результат - Стркутра - Шаблон
//
Функция ШаблоныСобытия(Знач ВставитьГиперссылкуОтписаться = Ложь) Экспорт
	
	Результат = Новый Структура;
	
	// Блок заголовка события:
	// Параметры:
	//	<!-- object_info --> - место для вставки шаблона объекта
	//	<!-- event_date -->	 - дата события в формате "01.01.0001 00:01"
	//	<!-- event_user -->	 - ФИО пользователя
	//	<!-- event_data -->	 - место для вставки данных события
	ЗаголовокСобытия = 
	"<table>
	|	<tr><td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 14px; line-height: 14px;""><!-- event_date --> <strong style = ""margin-left: 5px;""><!-- event_user --></strong> внес(-ла) изменения:</td></tr>
	|</table>";
	
	Результат.Вставить("ЗаголовокСобытия", ЗаголовокСобытия);
	
	Результат.Вставить("ЗаголовокКомментария", "<table><tr><td class=""f14"">и добавлен комментарий:</td></tr></table>");
	
	// Блок заголовка события комментария:
	// Параметры:
	//	<!-- event_date -->	 - дата события в формате "01.01.0001 00:01"
	//	<!-- event_user -->	 - ФИО пользователя
	ЗаголовокСобытияКомментария = 
	"<table>
	|	<tr><td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 14px; line-height: 14px;""><!-- event_date --> <strong style = ""margin-left: 5px;""><!-- event_user --></strong> добавил(-а) комментарий:</td></tr>
	|</table>";
	
	Результат.Вставить("ЗаголовокСобытияКомментария", ЗаголовокСобытияКомментария);
	
	// Таблица изменений
	// Параметры:
	//	<!-- events -->	 - место для вывода событий
	Результат.Вставить("ТаблицаИзменений", "<table style = ""width: 580px; margin-top: 10px;""><!-- events --></table>");
	
	// Блок комментария
	// Параметры:
	//	<!-- comment -->	 - текст комментария
	Результат.Вставить("Комментарий", "<table><tr><td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; line-height: 16px; height: 16px;""></td></tr><tr><td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 14px; line-height: 14px; padding: 16px; background-color:#f2f2f2; border-radius: 8px;""><!-- comment --></td></tr></table>");
	
	// Блок для вывода информации объекта
	// Параметры:
	//	<!-- object_title -->	-	название объекта, просто тема без номера
	//	<!-- object_preview -->	-	представление объекта в формате "[ТипОбъекта] [НомерКодОбъекта]. [ВидОбъекта]", например "Заявка на разработку ЗР000000001. Ошибка"
	//  <!-- unsubscribe_link -->   -   ссылка для отписки от оповещений
	//	<!-- object_link -->	 	-	навигационная ссылка на объект
	//	<!-- author -->	 		-	автор объекта
	//	<!-- author-email -->	-	почта автора объекта
	ШаблонОбъекта = 
	"<table>
	|	<tr><td colspan=""2"" style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 18px; line-height: 18px;""><a href=""<!-- object_link -->"" style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; text-align: left; line-height: 1.3; text-decoration: none;""><!-- object_title --></a></td></tr>
	|	<tr><td width=""50%"" style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 14px; line-height: 14px; color: #444;""><!-- object_preview --></td>
	|   <td width=""50%"" align= ""right"" ><!-- unsubscribe --></td></tr>
	|	<tr><td colspan=""2"" style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 14px; line-height: 14px; color: #444;"">Автор: <a href=""mailto:<!-- author-email -->"" style = ""font-family: Verdana, Arial, sans-serif; font-weight: bold; padding: 0; margin: 0; text-align: left; line-height: 1.3; text-decoration: underline; color:#000000""><!-- author --></a></td></tr>
	|	<tr><td colspan=""2"" style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; line-height: 16px; height: 16px;""></td></tr>
	|</table>";
	
	Если ВставитьГиперссылкуОтписаться Тогда  
		ШаблонОбъекта = СтрЗаменить(ШаблонОбъекта, "<!-- unsubscribe -->", "<a href=""<!-- unsubscribe_link -->"" style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; text-decoration: underline; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 12px; line-height: 14px; color:#444;"">Отписаться</a>");
	Иначе
		ШаблонОбъекта = СтрЗаменить(ШаблонОбъекта, "<!-- unsubscribe -->", "");  
	КонецЕсли;

	Результат.Вставить("ШаблонОбъекта", ШаблонОбъекта);
	
	Возврат Результат;
	
КонецФункции

Функция ШаблоныКомментариев() Экспорт
	
	Результат = Новый Структура;
	
	// Блок заголовка события комментария:
	// Параметры:
	//	<!-- event_date -->	 - дата события в формате "01.01.0001 00:01"
	//	<!-- event_user -->	 - ФИО пользователя
	//	<!-- comment -->	 - текст комментария
	ЗаголовокСобытияКомментария = 
	"<table>
	|	<tr><td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 14px; line-height: 14px;""><!-- event_date --> <strong style = ""margin-left: 5px;""><!-- event_user --></strong> добавил(-а) комментарий:</td></tr>
	|</table>
	|<table><tr><td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; line-height: 16px; height: 16px;""></td></tr><tr><td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 14px; line-height: 14px; padding: 16px; background-color:#f2f2f2; border-radius: 8px;""><!-- comment --></td></tr></table>";
	
	Результат.Вставить("Комментарий", ЗаголовокСобытияКомментария);

	ШаблонСтатуса = 
	// Блок заголовка события комментария:
	// Параметры:
	//	<!-- status -->	 - текст комментария
	"<table>
	|	<tr><td colspan=""2"" style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 14px; line-height: 14px;"">Статус: <strong style = ""margin-left: 5px;""><!--status--></strong></td></tr>
	|</table>";
	
	Результат.Вставить("Статус", ШаблонСтатуса);

	// Блок заголовка события комментария:
	// Параметры:
	//	<!-- event_date -->	 - дата события в формате "01.01.0001 00:01"
	//	<!-- event_user -->	 - ФИО пользователя
	//	<!-- comment -->	 - текст комментария
	ЗаголовокСобытияИзмененияКомментария = 
	"<table>
	|	<tr><td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 14px; line-height: 14px;""><!-- event_date --> <strong style = ""margin-left: 5px;""><!-- event_user --></strong> изменил(-а) комментарий:</td></tr>
	|</table>
	|<table><tr><td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; line-height: 16px; height: 16px;""></td></tr><tr><td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 14px; line-height: 14px; padding: 16px; background-color:#f2f2f2; border-radius: 8px;""><!-- comment --></td></tr></table>";
	
	Результат.Вставить("ИзменениеКомментария", ЗаголовокСобытияИзмененияКомментария);
	
	// Блок заголовка события комментария:
	// Параметры:
	//	<!-- event_date -->	 - дата события в формате "01.01.0001 00:01"
	//	<!-- event_user1 --> - ФИО автора ответа
	//	<!-- event_user2 --> - ФИО пользователя родительского комментария
	//	<!-- comment -->	 - текст комментария
	ЗаголовокСобытияОтветаНаКомментарий = 
	"<table>
	|	<tr><td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 14px; line-height: 14px;""><!-- event_date --> <strong style = ""margin-left: 5px;""><!-- event_user1 --></strong> ответил(-а) <strong style = ""margin-left: 5px;""><!-- event_user2 --></strong>:</td></tr>
	|</table>
	|<table><tr><td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; word-break: keep-all; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; line-height: 16px; height: 16px;""></td></tr><tr><td style = ""font-family: Verdana, Arial, sans-serif; font-weight: normal; padding: 0; margin: 0; word-wrap: normal; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; font-size: 14px; line-height: 14px; padding: 16px; background-color:#f2f2f2; border-radius: 8px;""><!-- comment --></td></tr></table>";
	
	Результат.Вставить("Ответ", ЗаголовокСобытияОтветаНаКомментарий);
	
	Возврат Результат;
	
КонецФункции

// Функция - Получить шаблоны для формирования электронного письма.
//
// Параметры:
// КаталогФайлов - Строка - Каталог файлов, для записи картинки. Должен очищаться по окончании отправки письма.
//
// Возвращаемое значение:
// Шаблоны - Структура - Фрагменты HTML контента письма. 
//
Функция ШаблоныЭлектронногоПисьма(Знач КаталогФайлов = "") Экспорт
	
	Шаблоны = Новый Структура;
	
	АдресДляВебКлиента = WebОкружениеВызовСервера.АдресПубликацииИнформационнойБазы();
	
	Если ПустаяСтрока(КаталогФайлов) Тогда
		
		ИмяФайлаКартинкиШапкиПисьма = "<!-- img_name_ШапкаЭлектронногоПисьма -->";
		ИмяФайлаКартинкиЛоготипа = "<!-- img_name_ЛоготипSDMS -->";
		
	Иначе
		
		// Попытка получения картинки шапки письма
		Попытка
			ИмяФайлаКартинкиШапкиПисьма = КаталогФайлов + РаботаСФайламиКлиентСервер.СоздатьУникальноеИмяФайла(".png");
			БиблиотекаКартинок.ШапкаЭлектронногоПисьма.Записать(ИмяФайлаКартинкиШапкиПисьма);
		Исключение
			ЗаписьЖурналаРегистрации(ИмяСобытияДляЖурналаРегистрации(), УровеньЖурналаРегистрации.Ошибка, , ,
				СтрШаблон("Не удалось сохранить картинку шапки письма по причине: %1.", ОписаниеОшибки()));
			ИмяФайлаКартинкиШапкиПисьма = "";
		КонецПопытки;
		
		// Попытка получения картинки ЛоготипSDMS
		Попытка
			ИмяФайлаКартинкиЛоготипа = КаталогФайлов + РаботаСФайламиКлиентСервер.СоздатьУникальноеИмяФайла(".png");
			БиблиотекаКартинок.ЛоготипSDMS.Записать(ИмяФайлаКартинкиЛоготипа);
		Исключение
			ЗаписьЖурналаРегистрации(ИмяСобытияДляЖурналаРегистрации(), УровеньЖурналаРегистрации.Ошибка, , ,
				СтрШаблон("Не удалось сохранить картинку логотип SDMS по причине: %1.", ОписаниеОшибки()));
			ИмяФайлаКартинкиЛоготипа = "";
		КонецПопытки;
		
	КонецЕсли;
	
	// Шаблон письма на HTML, который является основой для письма. 
	// Содержит параметры для замены функцией СтрЗаменить:
	//<!-- content --> - сформированные данные письма.
	СтруктураЭлектронногоПисьма = СтрШаблон("<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN' 'http://www.w3.org/TR/html4/loose.dtd'>
	|<html lang='ru'>
	|<head>
	|<meta http-equiv='Content-Type' content='text/html; charset=utf-8'>
	|<title>Автоматическое уведомление - Система задач SDMS</title>
	|<style type='text/css'>a,a:visited{color:#0052cc;text-decoration:none;}a:hover,a:active{color:#147dc2;}</style>
	|</head>
	|<body style='font-family: PT Sans; padding: 0; margin: 0; text-align: left; line-height: 20px;'>
	|<center>
	|	<table border='0' cellpadding='0' cellspacing='0' style='width: 640px; margin: 0; padding: 0; border-top:0;'>
	|	<tr>
	|		<td style='margin-top: 24px;'>
	|			<table border='0' cellpadding='0' cellspacing='0' style='width: 100%%; margin: 0; padding: 0;'>
	|			<tr>
	|				<td style='text-align: center; height: 126px;'><img style:'background-size: contain; display: block;' src='%1' alt='' border='0' width='640px' height='126px'></td>
	|			</tr>
	|			</table>
	|			<table border='0' cellpadding='0' cellspacing='0' style='width: 100%%; margin: 0; padding: 0; border: 1px solid; border-color: #EEEEEE;'>
	|				<!-- content -->
	|			</table>
	|		</td>
	|	</tr>
	|	</table>
	|</center>
	|</body>
	|</html>", ИмяФайлаКартинкиШапкиПисьма);
	
	Шаблоны.Вставить("СтруктураЭлектронногоПисьма", СтруктураЭлектронногоПисьма);
	
	// Левая часть шапки заполняется логотипом SDMS, справа размещаются данные в двух колонках.
	// Параметры:
	//<!-- right_table_1 --> - правая таблица первая колонка, используется для внесения текста или картинки по левую часть макета.
	//<!-- right_table_2 --> - правая таблица последняя колонка, используется для внесения текста или картинки по левую часть макета.
	ШапкаСЛоготипом = СтрЗаменить("<tr>
	|<td>
	|	<table border='0' cellpadding='0' cellspacing='0' style='width: 100%;'>
	|	<tr>
	|		<td style='vertical-align: top'>
	|			<table align='left' border='0' cellpadding='0' cellspacing='0' style='margin: 0; padding: 0;'>
	|				<tr style='font-family: Quicksand; font-size: 18px; font-weight: 700; line-height: 20px; text-align: left; text-underline-position: from-font; text-decoration-skip-ink: none; padding: 0; margin: 0; word-wrap: break-word; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; color: #333333'>
	|					<td style='padding: 10px 0 0 28px;'><img style:'background-size: contain; display: block;' src='<!-- sdms_logo -->' alt='' border='0'></td>
	|					<td style='padding: 10px 7px 0;'><b>SDMS</b></td>
	|			</tr></table>
	|		</td>
	|		<td style='vertical-align: top'>
	|			<table align='right' border='0' cellpadding='0' cellspacing='0' style='margin: 0; padding: 0;'>
	|				<tr style='font-family: PT Sans; font-size: 14px; font-weight: 400; line-height: 20px; text-align: left; text-underline-position: from-font; text-decoration-skip-ink: none; padding: 0; margin: 0; word-wrap: break-word; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; color: #333333'>
	|					<td style='padding: 10px 7px 0; margin: 0;'><!-- right_table_1 --></td>
	|					<td style='padding: 10px 28px 0 0'><!-- right_table_2 --></td>
	|			</tr></table>
	|		</td>
	|	</tr></table>
	|</td></tr>", "<!-- sdms_logo -->", ИмяФайлаКартинкиЛоготипа);
	
	Шаблоны.Вставить("ШапкаСЛоготипом", ШапкаСЛоготипом);
	
	// Подготовленный подвал письма с ссылкой на SDMS по центру письма.
	ПодвалПисьма = СтрШаблон("<tr>
	|	<td>
	|		<table border='0' cellpadding='0' cellspacing='0' style = 'width: 100%%;'>
	|			<tr>
	|				<td style='padding: 15px 1px 15px 28px; text-align: right; width: 45%%;'><img style:'background-size: contain; display: block;' src='%3' alt='' border='0'></td>
	|				<td style='padding: 15px 28px 15px 1px; width: 55%%; font-family: PT Sans; font-size: 14px; font-weight: 400; line-height: 20px; text-align: left; text-underline-position: from-font; text-decoration-skip-ink: none;'>
	|				<a href='%1' style = 'font-family: PT Sans; font-size: 14px; font-weight: 400; line-height: 20px; padding: 0; text-align: center; text-underline-position: from-font; text-decoration-skip-ink: none;'>&nbsp;SDMS </a>%2
	|				</td>
	|			</tr>
	|		</table>
	|	</td>
	|</tr>", АдресДляВебКлиента, Формат(ТекущаяДатаСеанса(), "ДФ=yyyy"), ИмяФайлаКартинкиЛоготипа);
	
	Шаблоны.Вставить("ПодвалПисьма", ПодвалПисьма);
	
	// Дополнительный подвал письма с ссылкой на SDMS.
	ДополнительныйПодвалПисьма = СтрШаблон("<tr>
	|<td>
	|	<table border='0' cellpadding='0' cellspacing='0' style = 'width: 100%%;'>
	|		<tr style='font-family: PT Sans;'><td style='padding: 15px 28px 15px; font-family: Inter; font-size: 12px; font-weight: 400; line-height: 14px; text-align: left; text-underline-position: from-font; text-decoration-skip-ink: none;'>
	|		Более подробную информацию можно посмотреть на
	|		<a href='%1'> %1</a>.
	|		</td></tr>
	|	</table>
	|</td></tr>", АдресДляВебКлиента);
	
	Шаблоны.Вставить("ДополнительныйПодвалПисьма", ДополнительныйПодвалПисьма);

	// Основной контент, строка в письме без табличного разделения со стандартным отступом.
	// Параметры:
	//<!-- content --> - наполнение.
	//<!-- font_size --> - размер шрифта.
	БлокОсновногоТекста = "<tr>
	|<td>
	|	<table border='0' cellpadding='0' cellspacing='0' style='margin: 0; padding: 0;'>
	|		<tr style='font-family: PT Sans; font-size: <!-- font_size -->; font-weight: 400; line-height: 20px; text-align: left; text-underline-position: from-font; text-decoration-skip-ink: none; color: #333333;'>
	|			<td style='padding: 25px 28px 0;'><!-- content --></td>
	|		</tr>
	|	</table>
	|</td></tr>";
	
	Шаблоны.Вставить("БлокОсновногоТекста", БлокОсновногоТекста);
	
	// Блок из двух таблиц для разделения данных по две стороны письма, значения могут не заполняться.
	// Параметры:
	//<!-- left_table_1 --> - левая таблица первая колонка, используется для внесения текста или картинки по левую часть макета.
	//<!-- left_table_2 --> - левая таблица последняя колонка, используется для внесения текста или картинки по левую часть макета.
	//
	//<!-- right_table_1 --> - правая таблица первая колонка, используется для внесения текста или картинки по правую часть макета.
	//<!-- right_table_2 --> - правая таблица последняя колонка, используется для внесения текста или картинки по правую часть макета.
	БлокДвеТаблицы = "<tr>
	|<td>
	|	<table border='0' cellpadding='0' cellspacing='0' style='width: 100%;'>
	|	<tr>
	|		<td style='vertical-align: top'>
	|			<table align='left' border='0' cellpadding='0' cellspacing='0' style='margin: 0; padding: 0;'>
	|				<tr style='font-family: PT Sans; font-size: 14px; font-weight: 400; line-height: 20px; text-align: left; text-underline-position: from-font; text-decoration-skip-ink: none; padding: 0; margin: 0; word-wrap: break-word; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; color: #333333'>
	|					<td style='padding: 10px 7px 0 56px;'><!-- left_table_1 --></td>
	|					<td style='padding: 10px 0 0;'><!-- left_table_2 --></td>
	|				</tr>
	|			</table>
	|		</td>
	|		<td style='vertical-align: top'>
	|			<table align='right' border='0' cellpadding='0' cellspacing='0' style='margin: 0; padding: 0;'>
	|				<tr style='font-family: PT Sans; font-size: 14px; font-weight: 400; line-height: 20px; text-align: left; text-underline-position: from-font; text-decoration-skip-ink: none; padding: 0; margin: 0; word-wrap: break-word; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; color: #333333'>
	|					<td style='padding: 10px 7px 0; margin: 0;'><!-- right_table_1 --></td>
	|					<td style='padding: 10px 28px 0 0'><!-- right_table_2 --></td>
	|				</tr>
	|			</table>
	|		</td>
	|	</tr>
	|	</table>
	|</td>
	|</tr>";
	
	Шаблоны.Вставить("БлокДвеТаблицы", БлокДвеТаблицы);
	
	// Блок из трех таблиц для разделения данных на левую, правую и центральную стороны письма, значения могут не заполняться.
	// Параметры:
	//<!-- left_table --> - левая таблица, используется для внесения текста или картинки по левую часть макета.
	//<!-- center_table --> - центральная таблица, используется для внесения текста или картинки после левой части макета.
	//<!-- right_table --> - правая таблица, используется для внесения текста или картинки по левую часть макета.
	БлокТриТаблицы = "<tr>
	|<td>
	|	<table border='0' cellpadding='0' cellspacing='0' style='width: 100%;'>
	|	<tr>
	|		<td style='vertical-align: top'>
	|			<table align='left' border='0' cellpadding='0' cellspacing='0' style='margin: 0; padding: 0;'>
	|			<tr style='font-family: PT Sans; font-size: 14px; font-weight: 400; line-height: 20px; text-align: left; text-underline-position: from-font; text-decoration-skip-ink: none; padding: 0; margin: 0; word-wrap: break-word; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; color: #333333'>
	|				<td style='padding: 10px 0 0 28px;'><!-- left_table --></td>
	|			</tr>
	|			</table>
	|		</td>
	|		<td style='vertical-align: top'>
	|			<table align='left' border='0' cellpadding='0' cellspacing='0' style='margin: 0; padding: 0;'>
	|			<tr style='font-family: PT Sans; font-size: 14px; font-weight: 400; line-height: 20px; text-align: left; text-underline-position: from-font; text-decoration-skip-ink: none; padding: 0; margin: 0; word-wrap: break-word; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; color: #333333'>
	|				<td style='padding: 10px 0 0;'><!-- center_table --></td>
	|			</tr>
	|			</table>
	|		</td>
	|		<td style='vertical-align: top'>
	|			<table align='right' border='0' cellpadding='0' cellspacing='0' style='margin: 0; padding: 0;'>
	|			<tr style='font-family: PT Sans; font-size: 14px; font-weight: 400; line-height: 20px; text-align: left; text-underline-position: from-font; text-decoration-skip-ink: none; padding: 0; margin: 0; word-wrap: break-word; -webkit-hyphens: auto; -moz-hyphens: auto; hyphens: auto; vertical-align: top; text-align: left; color: #333333'>
	|				<td style='padding: 10px 28px 0 0px'><!-- right_table --></td>
	|			</tr>
	|			</table>
	|		</td>
	|	</tr>
	|	</table>
	|</td>
	|</tr>";
	
	Шаблоны.Вставить("БлокТриТаблицы", БлокТриТаблицы);
	
	// Блок с выравниванием по центру.
	// Параметры:
	//<!-- content --> - наполнение.
	//<!-- font_size --> - размер шрифта.
	ЦентральныйБлок = "<tr>
	|<td>
	|	<table border='0' cellpadding='0' cellspacing='0' style = 'width: 100%;'>
	|	<tr style='font-family: PT Sans; font-weight: 400; color: #333333;'>
	|		<td style='padding: 10px 28px 0; font-family: PT Sans; font-size: <!-- font_size -->; font-weight: 400; line-height: 20px; text-align: center; text-underline-position: from-font; text-decoration-skip-ink: none; text-align: center; color: #333333;'>
	|			<!-- content -->
	|		</td>
	|	</tr>
	|	</table>
	|</td></tr>";
	
	Шаблоны.Вставить("ЦентральныйБлок", ЦентральныйБлок);
	
	// Разделительная линия со стандартным отступами для текста письма.
	РазделительнаяЛиния = "<tr><td>
	|	<table border=0 cellspacing=0 cellpadding=0 width=100% style='width:100%'>
	|	<tr>
	|		<td style='padding: 5px 0; width:28px;'></td>
	|		<td style='border-bottom:solid #EEEEEE 1.0pt; padding: 5px 0;'></td>
	|		<td style='padding: 5px 0; width:28px'></td>
	|	</tr>
	|	</table>
	|</td></tr>";
	
	Шаблоны.Вставить("РазделительнаяЛиния", РазделительнаяЛиния);
	
	// Блок текста комментария.
	// Параметры:
	//<!-- content --> - наполнение.
	Комментарий = "<tr>
	|<td>
	|	<table border=0 cellspacing=0 cellpadding=0 width=100% style='width:100%'>
	|	<tr style='font-family: PT Sans;  font-size: 14px; font-weight: 400; line-height: 20px; color: #333333; text-align: left;'>
	|		<td style='padding: 10px 0; width:28px;'></td>
	|		<td style='line-height: 20px; background-color: #F7F7F7; padding: 20px;'><!-- content --></td>
	|		<td style='padding: 10px 0; width:28px'></td>
	|	</tr>
	|	</table>
	|</td></tr>";
	
	Шаблоны.Вставить("Комментарий", Комментарий);
	
	// Картинка с управление шириной и высотой
	// Параметры:
	//<!-- src_image --> - имя полученного файла картинки.
	//<!-- width_image --> - ширина картинки, можно не заполнять, будет в размер файла картинки.
	//<!-- height_image --> - высота картинки, можно не заполнять, будет в размер файла картинки.
	Шаблоны.Вставить("ПолеКартинки", "<img src='<!-- src_image -->' alt='' border='0' width='<!-- width_image -->' height='<!-- height_image -->' style:'display: block;'>");
	
	// Ссылка на ресурс.
	// Параметры:
	//<!-- link --> - ссылка ресурса, на который требуется переход.
	//<!-- title_link --> - заголовок, который будет отображен для ссылки.
	Шаблоны.Вставить("АктивнаяСсылка", "<a href='<!-- link -->' target='_blank'><!-- title_link --></a>");
	
	// Новое электронное письмо пользователю.
	// Параметры:
	//<!-- email --> - адрес электронной почты для отправки письма.
	//<!-- user_name --> - отображаемое имя.
	Шаблоны.Вставить("ЭлектронноеПисьмо", "<a href='mailto:<!-- email -->' style='font-weight: bold; text-decoration: none; color:#000000' target='_blank'><!-- user_name --></a>");
	
	// Оформление текста для нового значения, цвет текста зеленый.
	// Параметры:
	//<!-- value --> - строка.
	Шаблоны.Вставить("НовоеЗначение", "<span style='color:#30B25D'><!-- value --></span>");
	
	// Оформление текста для старого значения, цвет текста красный, зачеркнутый.
	// Параметры:
	//<!-- value --> - строка.
	Шаблоны.Вставить("СтароеЗначение", "<span style='text-decoration: line-through; color:#FF6558'><!-- value --></span>");
	
	// Шаблон заголовка события, есть зависимое регулярное выражение в "РегламентныеЗаданияСервер", поэтому важен заданный формат.
	// Параметры:
	//  <!-- event_date --> - Дата в формате "ДФ='dd.MM.yyyy ""в"" ЧЧ:мм'"
	//  <!-- user_name --> - Имя пользователя.
	//  <!-- event --> - Текст события.//добавил(-а) комментарий: / внес(-ла) изменения:
	Шаблоны.Вставить("ЗаголовокСобытия", "<!-- event_date --> <b><!-- user_name --></b> <!-- event -->");
	
	//Форматная строка даты
	Шаблоны.Вставить("ФорматДаты", "ДФ='dd.MM.yyyy ""в"" ЧЧ:мм'");
	
	Возврат Шаблоны;
	
КонецФункции

#КонецОбласти

#КонецЕсли

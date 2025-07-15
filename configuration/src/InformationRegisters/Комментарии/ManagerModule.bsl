///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, ООО ДНС Технологии
// SDMS (Software Development Management System) — это корпоративная система учета разработки и управления проектами 
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии General Public License (GNU GPL v3)
// Текст лицензии доступен по ссылке:
// https://www.gnu.org/licenses/gpl-3.0.html
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Область ПрограммныйИнтерфейс

Функция Добавить(Знач Объект, Знач Идентификатор, Знач Пользователь, Знач Комментарий, Знач ИдентификаторВладельца = Неопределено,
	Знач Служебный = Ложь, Знач ВиденВсем = Истина, ТекстОповещения = "", Знач Важный = Ложь) Экспорт
	
	Результат = Новый Структура("Успешно, ИдентификаторКомментария", Ложь, Неопределено);
	ТекущаяДата = ТекущаяДатаСеанса();
	Идентификатор = ?(ЗначениеЗаполнено(Идентификатор), Идентификатор, Новый УникальныйИдентификатор);
	ИдентификаторСтрока = Строка(Идентификатор);
	Пользователь = ?(ЗначениеЗаполнено(Пользователь), Пользователь, ПараметрыСеанса.ТекущийПользователь);
	
	// Подготовка записи в текущий регистр
	НаборЗаписей = СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Период.Установить(ТекущаяДата);
	НаборЗаписей.Отбор.Объект.Установить(Объект);
	НаборЗаписей.Отбор.Идентификатор.Установить(ИдентификаторСтрока);
	
	НоваяЗапись = НаборЗаписей.Добавить();
	НоваяЗапись.Период = ТекущаяДата;
	НоваяЗапись.Объект = Объект;
	НоваяЗапись.Идентификатор = ИдентификаторСтрока;
	НоваяЗапись.Пользователь = Пользователь;
	НоваяЗапись.Комментарий = Комментарий;
	НоваяЗапись.Служебный = Служебный;
	НоваяЗапись.Общедоступный = ВиденВсем;
	НоваяЗапись.Важный = Важный;
	
	// Если заполнен идентификатор владельца, то подготовим запись
	// для помещения в регистр СвязиКомментариев
	НаборЗаписейСвязь = Неопределено;
	Если ЗначениеЗаполнено(ИдентификаторВладельца) Тогда
		ИдентификаторВладельца = Строка(ИдентификаторВладельца);
		НаборЗаписейСвязь = РегистрыСведений.СвязиКомментариев.СоздатьНаборЗаписей();
		НаборЗаписейСвязь.Отбор.Родитель.Установить(ИдентификаторВладельца);		
		НаборЗаписейСвязь.Отбор.Подчиненный.Установить(ИдентификаторСтрока);
		
		НоваяЗаписьСвязь = НаборЗаписейСвязь.Добавить();
		НоваяЗаписьСвязь.Родитель = ИдентификаторВладельца;
		НоваяЗаписьСвязь.Подчиненный = ИдентификаторСтрока;

		// нужно добавить для комментариев вместе с конвертацией	
		// НоваяЗаписьСвязь.ВысшийРодитель = ПолучитьВысшегоРодителя(ИдентификаторВладельца);
	КонецЕсли;
	
	НачатьТранзакцию();
	Попытка
		НаборЗаписей.Записать();
		Если ЗначениеЗаполнено(НаборЗаписейСвязь) Тогда
			НаборЗаписейСвязь.Записать();
		КонецЕсли;
		ЗафиксироватьТранзакцию();
		Результат.Успешно = Истина;
		Результат.ИдентификаторКомментария = Идентификатор;
	Исключение
		ОтменитьТранзакцию();
		ЗаписьЖурналаРегистрации("Комментарии. Добавление", УровеньЖурналаРегистрации.Ошибка, , , ОписаниеОшибки());
	КонецПопытки;
	
	Если Результат.Успешно И ЗначениеЗаполнено(ТекстОповещения) Тогда
		Взаимодействие.ДобавлениеКомментария(Объект, Пользователь, ТекстОповещения, Идентификатор, ТекущаяДата, ВиденВсем);
	КонецЕсли;
	
	Возврат Результат;
	
КонецФункции

Функция Изменить(Знач Объект, Знач Идентификатор, Знач Комментарий, Знач ВиденВсем, Знач ТекстОповещения = "") Экспорт
	
	РезультатЗаписи = Новый Структура("Успешно, ДатаСозданияКомментария", Истина, Неопределено);
	
	ДатаИзменения = ТекущаяДатаСеанса();
	
	НаборЗаписей = СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Объект.Установить(Объект);
	НаборЗаписей.Отбор.Идентификатор.Установить(Строка(Идентификатор));
	
	НаборЗаписей.Прочитать();
	
	Если НаборЗаписей.Количество() = 1 Тогда
		Запись = НаборЗаписей.Получить(0);
		
		// Добавляем дату создания комментария текущей датой,
		// что бы корректно софрмировалось почтовое уведомление
		РезультатЗаписи.ДатаСозданияКомментария = ДатаИзменения;
		Запись.Комментарий = Комментарий;
		Запись.ДатаИзменения = ДатаИзменения;
		Запись.Общедоступный = ВиденВсем;
		Попытка
			НаборЗаписей.Записать();
		Исключение
			РезультатЗаписи.Успешно = Ложь;
		КонецПопытки;
	КонецЕсли;
	
	Если РезультатЗаписи.Успешно И ЗначениеЗаполнено(ТекстОповещения) Тогда
		Пользователь = ПараметрыСеанса.ТекущийПользователь;
		Взаимодействие.ИзменениеКомментария(Объект, Пользователь, ТекстОповещения, Идентификатор, ДатаИзменения);
	КонецЕсли;
	
	Возврат РезультатЗаписи;
	
КонецФункции

Функция ИзменитьВажность(Знач Объект, Знач Идентификатор) Экспорт
	
	Результат = Истина;
	
	НаборЗаписей = СоздатьНаборЗаписей();
	НаборЗаписей.Отбор.Объект.Установить(Объект);
	НаборЗаписей.Отбор.Идентификатор.Установить(Идентификатор);
	НаборЗаписей.Прочитать();
	
	НаборЗаписей.Получить(0).Важный = НЕ НаборЗаписей.Получить(0).Важный;
	
	Попытка
		НаборЗаписей.Записать();
	Исключение
		Результат = Ложь;
	КонецПопытки;
	
	Возврат Результат;
	
КонецФункции

Функция Удалить(Знач Объект, Знач Идентификатор, Знач Пользователь = Неопределено) Экспорт
	
	Результат = Новый Структура("Успешно, Сообщение", Истина, "");
	
	Если Пользователь = Неопределено Тогда
		Пользователь = ПараметрыСеанса.ТекущийПользователь;
	КонецЕсли;
	
	// Проверка наличия ответов на комментарий
	НаборЗаписейСвязи = РегистрыСведений.СвязиКомментариев.СоздатьНаборЗаписей();
	НаборЗаписейСвязи.Отбор.Родитель.Установить(Идентификатор);
	НаборЗаписейСвязи.Прочитать();
	
	// Если на комментарий нет ответов
	Если НаборЗаписейСвязи.Количество() = 0 Тогда
		
		// Отключаем отбор набора записей регистра СвязиКомментариев
		НаборЗаписейСвязи.Отбор.Сбросить();
		
		НаборЗаписей = СоздатьНаборЗаписей();
		НаборЗаписей.Отбор.Объект.Установить(Объект);
		НаборЗаписей.Отбор.Идентификатор.Установить(Идентификатор);
		НаборЗаписей.Прочитать();
		
		Если НаборЗаписей.Количество() = 0 Тогда
			Результат.Успешно = Ложь;
			Результат.Сообщение = "Комментарий не найден.";
		Иначе
			Запись = НаборЗаписей.Получить(0);
			
			Если Запись.Пользователь <> Пользователь Тогда
				Результат.Успешно = Ложь;
				Результат.Сообщение = "Запрещено удалять чужие комментарии!";
				Возврат Результат;
			КонецЕсли;
			
			ТекущаяДата = ТекущаяДатаСеанса();
			
			Если (ТекущаяДата - Запись.Период) > 1800 Тогда
				Результат.Успешно = Ложь;
				Результат.Сообщение = "С момента публикации комментария прошло более 30 минут.";
			Иначе
				
				НаборЗаписей.Очистить();
				
				// Удаление связи с родителем при наличии
				НаборЗаписейСвязи.Отбор.Подчиненный.Установить(Идентификатор);
				
				// т.к. файлы комментария теперь привязаны к самому комментарию, то после удаления комментария, 
				// нужно удалить связь и файлы пометятся на удаление регламентным заданием
				НаборЗаписейФайлы = РегистрыСведений.ПрикрепленныеФайлы.СоздатьНаборЗаписей();
				НаборЗаписейФайлы.Отбор.Объект.Установить(Идентификатор);
				
				НачатьТранзакцию();
				Попытка
					НаборЗаписей.Записать();
					НаборЗаписейСвязи.Записать();					
					НаборЗаписейФайлы.Записать();
					
					РегистрыСведений.ОчередьСобытийНаОбработку.УдалитьОповещение(Объект, Новый УникальныйИдентификатор(Запись.Идентификатор));
					
					ЗафиксироватьТранзакцию();
				Исключение
					ОтменитьТранзакцию();
					Результат.Успешно = Ложь;
					Результат.Сообщение = ОписаниеОшибки();
				КонецПопытки;
			КонецЕсли;
		КонецЕсли;
	Иначе
		Результат.Успешно = Ложь;
		Результат.Сообщение = "На данный комментарий ответили.";
	КонецЕсли;
	
	Если Результат.Успешно Тогда
		Взаимодействие.УдалениеКомментария(Новый УникальныйИдентификатор(Идентификатор));
	КонецЕсли;
	
	Возврат Результат;
	
КонецФункции

Функция КлючиНастроек() Экспорт
	
	Возврат Новый Структура("КлючОбъекта, КлючНастроек", "РегистрСведений.Комментарии", "НастройкиКомментариев");
	
КонецФункции

Функция КоличествоКомментариев(Знач Объект) Экспорт
	
	// Определение объектов, участвующих в комментировании
	СписокОбъектов = ПолучитьСписокОбъектов(Объект);
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	Комментарии.Общедоступный КАК Общедоступный,
	|	ЕСТЬNULL(ВЫРАЗИТЬ(ЛичныеДелаСрезПоследних.Данные КАК Справочник.Филиалы), ЗНАЧЕНИЕ(Справочник.Филиалы.ПустаяСсылка)) КАК ПринадлежитФилиалу
	|ПОМЕСТИТЬ КомментарииОбъекта
	|ИЗ
	|	РегистрСведений.Комментарии КАК Комментарии
	|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ЛичныеДела.СрезПоследних(
	|				&ТекущаяДата,
	|				Событие = ЗНАЧЕНИЕ(Перечисление.СобытияПоЛичнымДелам.ПереведенВДругоеПодразделение)
	|					И (ВЫРАЗИТЬ(Данные КАК Справочник.Филиалы)) <> ЗНАЧЕНИЕ(Справочник.Филиалы.ПустаяСсылка)) КАК ЛичныеДелаСрезПоследних
	|		ПО Комментарии.Пользователь = ЛичныеДелаСрезПоследних.Сотрудник
	|ГДЕ
	|	Комментарии.Объект В(&СписокОбъектов)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ
	|	ЕСТЬNULL(СУММА(ДоступныеКомментарии.Комментарий), 0) КАК Количество
	|ИЗ
	|	(ВЫБРАТЬ
	|		1 КАК Комментарий
	|	ИЗ
	|		КомментарииОбъекта КАК КомментарииОбъекта
	|	ГДЕ
	|		КомментарииОбъекта.Общедоступный
	|	
	|	ОБЪЕДИНИТЬ ВСЕ
	|	
	|	ВЫБРАТЬ
	|		1
	|	ИЗ
	|		КомментарииОбъекта КАК КомментарииОбъекта
	|			ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.Филиалы КАК Филиалы
	|			ПО КомментарииОбъекта.ПринадлежитФилиалу = Филиалы.Ссылка
	|	ГДЕ
	|		НЕ КомментарииОбъекта.Общедоступный
	|		И &ПользовательИзITФилиала
	|		И Филиалы.ТипФилиала <> ЗНАЧЕНИЕ(Перечисление.ТипыФилиалов.НеIT)
	|	
	|	ОБЪЕДИНИТЬ ВСЕ
	|	
	|	ВЫБРАТЬ
	|		1
	|	ИЗ
	|		КомментарииОбъекта КАК КомментарииОбъекта
	|	ГДЕ
	|		НЕ КомментарииОбъекта.Общедоступный
	|		И &ПользовательИзITФилиала = ЛОЖЬ
	|		И КомментарииОбъекта.ПринадлежитФилиалу = &ФилиалПользователя) КАК ДоступныеКомментарии";
	
	ТипФилиала = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(ПараметрыСеанса.Филиал, "ТипФилиала");
	ПользовательИзITФилиала = (ТипФилиала <> Перечисления.ТипыФилиалов.НеIT);
	
	Запрос.УстановитьПараметр("ТекущаяДата", ТекущаяДатаСеанса());
	Запрос.УстановитьПараметр("СписокОбъектов", СписокОбъектов);
	Запрос.УстановитьПараметр("ФилиалПользователя", ПараметрыСеанса.Филиал);
	Запрос.УстановитьПараметр("ПользовательИзITФилиала", ПользовательИзITФилиала);
	
	Выборка = Запрос.Выполнить().Выбрать();
	Выборка.Следующий();
	
	Возврат Выборка.Количество;
	
КонецФункции

// TO DO: Удалить, после полного перехода на новый вариант комментариев, 
// и удаления из комментариев ссылок на прикрепленные файлы
Функция ПолучитьНаименованияФайловИзТекста(Знач ТекстДокумента) Экспорт
	
	// Для указания прикрепленного файла в комментарии после ссылки
	// на файл добавляется конструкция "<span class='saveFile'>".
	// Так как она добавляется в конце, для точного определения
	// ссылки именно на прикрепленный файл требуется проивзодить
	// поиск с конца строки, снача ищем конструкцию, затем теги
	// ссылки. В противном случае возникнут ошибки, так как результатом
	// поиска ссылки на файл может стать строка сверх большой длины
	// (>1026 симв. (выяснено "опытным" путем))
	// и при выполнении запроса для поиска ссылок на справочник файлы по
	// наименованию возникнет ошибка: 
	// "Невосстановимая ошибка  
	// Ошибка при выполнении запроса POST к ресурсу /e1cib/logForm:  
	// по причине:  
	// Ошибка SDBL:  
	// Поле "..." имеет неограниченную длину и не может участвовать в сравнении."
	
	// Массив для хранения имен прикрепленных файлов
	НаименованияФайлов = Новый Массив;
	
	КонечнаяПозиция = СтрНайти(ТекстДокумента, "<span class='saveFile'>", НаправлениеПоиска.СКонца);
	Пока КонечнаяПозиция <> 0 Цикл
		НачальнаяПозиция = СтрНайти(ТекстДокумента, "<a href=""", НаправлениеПоиска.СКонца, КонечнаяПозиция);
		Если НачальнаяПозиция <> 0 Тогда
			Подстрока = Сред(ТекстДокумента, НачальнаяПозиция, КонечнаяПозиция - НачальнаяПозиция - 2);
						
			ПозицияПоиска = СтрНайти(Подстрока, "\", НаправлениеПоиска.СКонца);
			Если ПозицияПоиска = 0 Тогда
				ПозицияПоиска = СтрНайти(Подстрока, "/", НаправлениеПоиска.СКонца);
			КонецЕсли;
			
			ИмяФайла = Сред(Подстрока, ПозицияПоиска + 1);
			НаименованияФайлов.Добавить(ИмяФайла);
		КонецЕсли;
		КонечнаяПозиция = СтрНайти(ТекстДокумента, "<span class='saveFile'>", НаправлениеПоиска.СКонца, НачальнаяПозиция);
	КонецЦикла;
	
	Возврат НаименованияФайлов;
	
КонецФункции

Функция ПолучитьСписокОбъектов(Знач Объект) Экспорт
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ РАЗРЕШЕННЫЕ
	|	СвязьОбъектов.Заявка КАК Объект
	|ПОМЕСТИТЬ ОбъектыКомментрирования
	|ИЗ
	|	РегистрСведений.СвязьОбъектовСЗаявкамиНаРазработку КАК СвязьОбъектов
	|ГДЕ
	|	ТИПЗНАЧЕНИЯ(&Источник) = ТИП(Документ.Задача)
	|	И СвязьОбъектов.Объект = &Источник
	|
	|ОБЪЕДИНИТЬ
	|
	|ВЫБРАТЬ
	|	СвязьОбъектовСЗаявкамиНаРазработку.Объект
	|ИЗ
	|	РегистрСведений.СвязьОбъектовСЗаявкамиНаРазработку КАК СвязьОбъектовСЗаявкамиНаРазработку
	|ГДЕ
	|	ТИПЗНАЧЕНИЯ(&Источник) = ТИП(Документ.Задача)
	|	И СвязьОбъектовСЗаявкамиНаРазработку.Объект = &Источник
	|
	|ОБЪЕДИНИТЬ
	|
	|ВЫБРАТЬ
	|	СвязьОбъектовСЗаявкамиНаРазработку.Заявка
	|ИЗ
	|	РегистрСведений.СвязьОбъектовСЗаявкамиНаРазработку КАК СвязьОбъектовСЗаявкамиНаРазработку
	|ГДЕ
	|	ТИПЗНАЧЕНИЯ(&Источник) = ТИП(Документ.ЗаявкаНаРазработку)
	|	И СвязьОбъектовСЗаявкамиНаРазработку.Заявка = &Источник
	|
	|ОБЪЕДИНИТЬ
	|
	|ВЫБРАТЬ
	|	СвязьОбъектовСЗаявкамиНаРазработку.Объект
	|ИЗ
	|	РегистрСведений.СвязьОбъектовСЗаявкамиНаРазработку КАК СвязьОбъектовСЗаявкамиНаРазработку
	|ГДЕ
	|	ТИПЗНАЧЕНИЯ(&Источник) = ТИП(Документ.ЗаявкаНаРазработку)
	|	И СвязьОбъектовСЗаявкамиНаРазработку.Заявка = &Источник
	|	И СвязьОбъектовСЗаявкамиНаРазработку.Объект ССЫЛКА Документ.Задача
	|
	|ОБЪЕДИНИТЬ
	|
	|ВЫБРАТЬ РАЗЛИЧНЫЕ
	|	ОбъектыВерхнегоУровняСтруктурыПодчиненности.ВысшийРодитель
	|ИЗ
	|	РегистрСведений.ОбъектыВерхнегоУровняСтруктурыПодчиненности КАК ОбъектыВерхнегоУровняСтруктурыПодчиненности
	|ГДЕ
	|	ТИПЗНАЧЕНИЯ(&Источник) = ТИП(Справочник.Проекты)
	|	И ОбъектыВерхнегоУровняСтруктурыПодчиненности.ВысшийРодитель = &Источник
	|
	|ОБЪЕДИНИТЬ
	|
	|ВЫБРАТЬ РАЗЛИЧНЫЕ
	|	ОбъектыВерхнегоУровняСтруктурыПодчиненности.Объект
	|ИЗ
	|	РегистрСведений.ОбъектыВерхнегоУровняСтруктурыПодчиненности КАК ОбъектыВерхнегоУровняСтруктурыПодчиненности
	|ГДЕ
	|	ТИПЗНАЧЕНИЯ(&Источник) = ТИП(Справочник.Проекты)
	|	И ОбъектыВерхнегоУровняСтруктурыПодчиненности.ВысшийРодитель = &Источник
	|	И ТИПЗНАЧЕНИЯ(ОбъектыВерхнегоУровняСтруктурыПодчиненности.Объект) <> ТИП(Документ.Задача)
	|
	|ОБЪЕДИНИТЬ
	|
	|ВЫБРАТЬ
	|	&Источник
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ РАЗРЕШЕННЫЕ
	|	ОбъектыКомментрирования.Объект КАК Объект,
	|	ПРЕДСТАВЛЕНИЕ(ОбъектыКомментрирования.Объект) КАК ПредставлениеОбъекта
	|ИЗ
	|	ОбъектыКомментрирования КАК ОбъектыКомментрирования
	|
	|УПОРЯДОЧИТЬ ПО
	|	Объект
	|АВТОУПОРЯДОЧИВАНИЕ";
	
	Запрос.УстановитьПараметр("Источник", Объект);
	
	Выборка = Запрос.Выполнить().Выбрать();
	СписокЗначений = Новый СписокЗначений;
	
	Пока Выборка.Следующий() Цикл
		СписокЗначений.Добавить(Выборка.Объект, Выборка.ПредставлениеОбъекта, Истина);
	КонецЦикла;
		
	Возврат СписокЗначений;
	
КонецФункции

Функция ПолучитьШаблоны() Экспорт
	
	Результат = Новый Структура;
	Результат.Вставить("Лента",                             "");
	Результат.Вставить("ОбластьКомментариев",               "");
	Результат.Вставить("Комментарий",                       "");
	Результат.Вставить("КомментарийНавигации",              "");
	Результат.Вставить("ПросмотренныйКомментарийНавигации", "");
	Результат.Вставить("Ссылка_Ответить",                   "");
	Результат.Вставить("Ссылка_Изменить",                   "");
	Результат.Вставить("Ссылка_Удалить",                    "");
	Результат.Вставить("Ссылка_ОтметитьВажным",             "");
	Результат.Вставить("Ссылка_ОткрытьВНовомОкне",          "");
	Результат.Вставить("Ссылка_СвернутьВетку",              "");
	Результат.Вставить("Ссылка_Скопировать",                "");
	
	Результат.Лента = СтрЗаменить(
	"<!DOCTYPE html>
	|<html>
	|	<head>
	|		<title></title>
	|		<meta http-equiv='X-UA-Compatible' content='IE=edge' />
	|		<style type='text/css'>
	|			html {height:100%; width:100%;}
	|			body {background:#fff; font-family: Arial, sans-serif; font-size:13px; min-width:600px; margin:0;}
	|			a {color:#0066bb; text-decoration:none;}
	|			a:hover {color:#00437a; text-decoration:none;}
	|			#comments{line-height:18px; margin: 0px 6px; float: left;}
	|			#comments_panel{float:right; padding:2px 5px; font-size:12px; font-weight:normal;}
	|			#comments_panel a{color:#0066bb; text-decoration:none; border-left:1px solid #666; border-right:1px solid #666; padding: 0 5px;}
	|			.comment{margin:0 0 2px 0; padding-top:8px; border-top:1px solid #aaa;}
	|			.comment h1{margin:0 0 2px 55px; padding:0; font-size:12px; font-weight:bold; border:0; height:16px; color:#4682b4;}
	|			.comment h1 .date{font-size:12px; font-weight:normal; color:#818181;}
	|			.comment h1 .answer{background:url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAALGPC/xhBQAAAAlwSFlzAAAOwgAADsIBFShKgAAAABl0RVh0U29mdHdhcmUAcGFpbnQubmV0IDQuMC4yMfEgaZUAAACySURBVDhPpZI7EoQgEES9upmEhtzAkNDQI5gREhISEs7SVOnKbFO1lMFD7OkePjqJyCuoOAIVNTnn8uA1Kmq899Jr8iMwjuMQay1t0rz02Pdd5nmuTVJKRfrWGuMFVsKq67rW4BNjjMQYi63TAEWYdPDJsiz3cYbD4DzPGgZNA2wZ3bdtq0eAMYQgzjkaBvcEARjZTaPGwqAxXXPNtRutgzroT6Pp/USAiiNQcQQq/o9MH3qP/quXxrf5AAAAAElFTkSuQmCC') center left no-repeat;height:16px;width:16px;margin-left:5px;display:inline-block;}
	|			.comment h1 a{color:#0066bb;text-decoration:none;}
	|			.comment h1 .comment_object a{font-size:12px;font-weight:normal;color:#818181;float:right;text-decoration:underline;}
	|			.comment h1 .comment_object a:hover{text-decoration:none;}
	|			.photo{width:50px;float:left;margin-right:5px;}
	|			.comment_body{min-height: 30px;margin:2px 0 8px 55px;}
	|			.comment_h1{margin:2px 0 8px 0px;color:#888888;font-weight:bold;}
	|			.comment_body_text{margin:0;}
	|			.comment_body_text p{margin:3px 0 2px 0;text-align:justify;}
	|			.comment_body_files{margin:0px 0 0px 0;font-size:11px;}
	|			.comment_body_files a{color:#0066bb;}
	|			.comment_body_files img{float:left;border:0;width:16px;height:16px;}
	|			.comment_body_panel{margin:5px 5px 0px 0px;color:#666;font-size:11px;-moz-user-select: none;-ms-user-select: none;-o-user-select: none;-webkit-user-select: none;user-select: none;}
	|			.comment_body_panel a{color:#666;font-size:11px;}
	|			.comment_child {position:relative;margin-left:54px;}
	|			.profile_image {background:url('data:image/png;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/4QBoRXhpZgAATU0AKgAAAAgABAEaAAUAAAABAAAAPgEbAAUAAAABAAAARgEoAAMAAAABAAIAAAExAAIAAAARAAAATgAAAAAAAABgAAAAAQAAAGAAAAABcGFpbnQubmV0IDQuMC4yMQAA/9sAQwAEAwMEAwMEBAMEBQQEBQYKBwYGBgYNCQoICg8NEBAPDQ8OERMYFBESFxIODxUcFRcZGRsbGxAUHR8dGh8YGhsa/9sAQwEEBQUGBQYMBwcMGhEPERoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoa/8AAEQgAMgAyAwEiAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/aAAwDAQACEQMRAD8A+rKKKkt1DTxKehcA/nWxmaVj4evLwBmAgjPIZ+p+gq1ceE7qJC0EqTY/hxtJrsQMDilrPmZdjy91ZGZXBVlOCD2NNrY8TLGuqt5XUqC4/wBr/wDVisetEQFFFFABVrTYlnv7eN22Kzjmqn4UqMyOrJ8rKcg+hoA9SFFVNMuxe2UMwOSy/N9R1qzI4jRmY4VQST7ViaHD+Jo1j1Zyrbi6hj7Hp/Ssepr25a8upZn53scfTtUH4VqjMWik/CimAfhTo42lcJEhdj0AGTWto+gvqX72VvLtwcZ7t9K7Gz063sE220YX1bufqalysOxFo1q1lp0MMnDgEsPQk5q5KgkidG6MpB/Gn0VmWeZ3dnNZTNHPGVIPB7GoPwr06e3iukKXEayIezCuW1fwz5EbT2BLIvLRnqB7GtFIlo5r8KKXAoqiT0DQhjSbXH9z+taVFFZPc0CiiikAU1uV5oooA8ukOJHx6miiitiT/9k=');float:left;height:50px;width:50px;}
	|			.service{background:#eeeeee;}
	|			.highPriority{background:#ffdddd;}
	|			.lowPriority{background:#ffffff;}
	|			.selected{background:#fff2e6}
	|			.width85{width: 85%;}
	|			.width100{width: 99.3%;}
	|			.hidden{display:none;}
	|			.transition{transition: 0.3s;}
	|			.togglePriorityImage{background:url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAvgAAAL4BsOPnlwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAADwSURBVCiRjZA9SsRgEIafNxGC26S10NoVtNjGHzRNsNoTaOEJthNtw5CksLLyAmKhh7AIeIVd7EQ777B8jE0iy26KDAzMzDsP8wM9ZmYjMxv1aVFfUdJ9FEV3gwHgyt2vBwFlWR4BY2BsZocb06uq2g8h3K6scwBkbfrh7p+dFsfx41YI4UfSEpj1bJBJygDc/SlN0291ipldSnoBdtagX3e/MbN3gLirNk3zlef5NpCvAQ9m9tx7tLtP23DZOsB0tecfqOt6DzgF5pImkibAHDgzs90NIIRw7O6v7n5eFMWiKIpFkiQXwJukk56HDLM/kDJLhLgehCkAAAAASUVORK5CYII=') center left no-repeat;height:12px;width:12px;margin-left:1px;margin-right:3px;display:inline-block;}
	|			.answerImage{background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAvgAAAL4BsOPnlwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAADgSURBVCiRtZCvTgNBEMZ/c5ypIsHUYXmBElSPTZ8ASXgHNMHszm5ypKK8AUEiyiNg9gEAhUZhqEAi4HKDgcu1KSmGz82X+f7MwH9ja5Wo63pYVdUg5/y+TlD0h5TSYdM0T8BoY0JK6cTM5sC2iLw65z6cc4uc82dfIAAxxilwtsbwDbgIIVx2lcxMfosHdoBZjDEsJfQqXQEDM7sGFiJyAIy/jfdV9bE72nt/IyJj4AW4VdXzEMLEzPaAO+AUVr7kvX8oy3IE3P9wqvpsZkdFUewuVdqElNJx27bzv+53+AIfDE7I7Z7jJAAAAABJRU5ErkJggg==) center left no-repeat;height:12px;width:12px;margin-left:1px;margin-right:3px;display:inline-block;}
	|			.editImage{background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAvgAAAL4BsOPnlwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAC4SURBVCiRnY8hDsJQEERnSWsJR+AOGCwXgCvAGSgJaaC7/9sWj0NxBwRnQeEwOMQXg4HmJ7QlsG4nb3Z2gB9HvgHe+zXJWZqm0zzPb70u2Mz6JAcAxiGEEwAkHZc3JBckJyICkqH1JefcFoB/rReSIzO7NyaYWQkgi6T9G/5IMLNSRGpYRFZFUVQxUxuccxWAZRdcG7z3c5KHuIaqWlO/BABIDiMtU9VdExwbziLyAHBV1WMb/Nc8Aeb/Swhlke6PAAAAAElFTkSuQmCC) center left no-repeat;height:12px;width:12px;margin-left:1px;margin-right:3px;display:inline-block;}
	|			.collapseImage{background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAvgAAAL4BsOPnlwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAACWSURBVCiR1ZCxCcNQDEQlrWJSufUiJpDUGeTD8bWHSenqT5LajQdx9XVp7GBMcBtyoEb3hE4S+Q+5e+PuzTfPjo2ccxsRJSJKzrk9HQDQkRxJXtcaAXR7Rvewqj7NrE8pzWu0S0QUkg8Ar88Gd29UdSB522ARkZTSTPKuqsN2k4mI1FoXM+sBTMfMACYz62uty9mjfqg3boxMgVTBVWwAAAAASUVORK5CYII=) center left no-repeat;height:12px;width:12px;margin-left:1px;margin-right:3px;display:inline-block;}
	|			.collapsedImage{background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAvgAAAL4BsOPnlwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAACSSURBVCiRzZCxDcJAFEPtX2SKdBEpQplNSEfDJHey7i9ChQSKxDRUSBnljiZBICHSxqX97MLANiWpltT+yVtJNQDY7FUkR0ndD7gjOQKo3gVJk5kNJG8ppX6BU0o9yauZDZImAODnmrvvcs53kicAKKWczewQQnguzFdhXt2XUi4AQPIYY3ysnuDujbs3q+A29ALWUSzaL9mlawAAAABJRU5ErkJggg==) center left no-repeat;height:12px;width:12px;margin-left:1px;margin-right:3px;display:inline-block;}
	|			.privateMessageImage{background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAvgAAAL4BsOPnlwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAFHSURBVCiRbY89S5thFIavc95Y0kpxaDoYkNYOpZOjbh1KUcHJQVyKQ5ZC/4DUGghtEcniH2iHDlHBQaGb6NKCmRx1cIgIaTIUUiuC5uN9bheVfJ3tcO6Lc93QZ8ofXz2p5F6m+t2sfank0o+IkwWMQYTMqbUuGpmRtfLVXcY7cD38JPiZ/lyaTH8pTSlo3x8/WGyPdAF6HS4bG/d7VF83eNOj9Hfp2XBrIPoqMQu212mtt2ZsJ5rx8tOVs2oCoBn5DCJzG5jrLiqRaUZeBL4lbs0c1B0rYb5pQX9kjFnEeW+HO08jj9s8YkTGAnBt+K++gBl5ZMcEfuPaid3eyfgfgo6qudHxHqBlKgh9B84sUI+CTmQUgJSCbTmARxwYKgKHUcyQGT+A57G8hmvagyYAGaxa9wcAgVWzL95jfACSwD9c2XTudPcGKaB4lLhd3EIAAAAASUVORK5CYII=) center left no-repeat;height:12px;width:12px;margin-left:1px;margin-right:3px;display:inline-block;}
	|			.deleteImage{background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAvgAAAL4BsOPnlwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAADaSURBVCiRtZExSkNREEXPeXEZ9haWdoqQBbiKRCMpBUkZhlSKpEkjGqzcgvY/FmKVys61+Mbm/2BInVsNlznD3BnYt+yKiDhVzzJzHhG19Uop5bbW+hERXwAHG1LPgTv1KCJGrb3MzIE6AbaBzHxQj4Eh8KsKDIDXzJzvrNRCzmazR+C6tZ6m0+lYza6ntxVIC3ChnrQD1qvV6r1pml0gIgqwVC8z81ldqyP1sN/vv3XQJkMpZZKZA+AFGGcmQE8dqj/A/RZQa21KKTe11sW/s14B3+rnzkP2pj9RnFjwEMuR6gAAAABJRU5ErkJggg==) center left no-repeat;height:12px;width:12px;margin-left:1px;margin-right:3px;display:inline-block;}
	|			.saveFile{background:url('data:image/gif;base64,R0lGODlhEAAQANUAAAAAAP///4WLlKmvuDVJYzZKZDhMZjlNZzhLZTtPaTlMZj5Ra0FUbkJVbkRXcEVYcUhbdEdac0ted0xfeE5hek9ie1NlflRmf1pshGx9lHKDmXaHnXWGnKettTdLZDtPaDxQaT5Sa0BUbVZpgVdqgVpthFxuhV9xiF5wh2J0i2V3jml7kmt9lG6Alm+Bl3KEmn2Fj36GkIWMlYyRl5OXnIiOlaeutqivtv///wAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAADgALAAAAAAQABAAAAZnQJxwSCwacYPNq3U7Ejk2XIflHLqGpqoGt8KdcJdqBpfCkXCTqgpXwlVwjyoKZ8FBcI0qxo1j4EJVIzgSOAs4B1UUOA44HzgEVRGFMQiPVSI4Mgo0OAVVAiBDCTVVODMeBAYwpaw4QQA7')center left no-repeat;height:14px;width:14px;margin-left:1px;margin-right:3px;display:inline-block;} 
	//          причина использования оператора !important в том, что при парсинге содержимого поля html документа средствами платформы
	//          при наличии тега img ему автоматически проставляется style="border:none" чтобы не удалять его после парсинга, просто перебиваем его.
	|			#comments img {width:auto;height:auto; border:1px solid #666 !important;border-radius:4px;max-height:400px;max-width:400px;}
	|			#comments .copy_img{vertical-align:top; border:none !important;}
	|			blockquote span{font: 10pt sans-serif;color: black;}
	|			blockquote {font: 12pt sans-serif;color: black; border-left: 3px solid #999;padding:10px;}
	|			blockquote blockquote{font: 10pt sans-serif;color: black;}
	|			blockquote footer{font: 10pt sans-serif;}
	|			#nav{position: fixed; right: 0; width: 14.3%; height: 100%; border-left:1px solid #aaa; -moz-user-select: none; -ms-user-select: none; -o-user-select: none; -webkit-user-select: none; user-select: none;}
	|			#nav ul{list-style-type: none; padding: 0;}
	|			#nav p{font-weight:bold; text-align: center;}
	|			#nav li{padding: 10px 10px 10px 10px; cursor: pointer; color: #000; text-decoration: none;}
	|			#nav li:hover{background-color: #555; color: white;} 
	|			#nav .visited{color: #666;}
	|			body { margin: 0; }
	|			#content{ overflow: auto; height: 100vh; width: 100vw; }
	|			div#content::-webkit-scrollbar { width: 12px; height: 12px }
	|			div#content::-webkit-scrollbar-track, div#content::-webkit-scrollbar-thumb { border-radius: 5px; border-style: solid; border-color: #fff }
	|			div#content::-webkit-scrollbar-track { background: #d6d6d6 }
	|			div#content::-webkit-scrollbar-thumb { background: #9a9a9a }
	|			div#content::-webkit-scrollbar-track:horizontal, div#content::-webkit-scrollbar-thumb:horizontal { border-width: 2px 0 }
	|			div#content::-webkit-scrollbar-track:vertical, div#content::-webkit-scrollbar-thumb:vertical { border-width: 0 2px }
	|			div#content::-webkit-scrollbar-thumb:hover { background: #757575 }
	|			div#content::-webkit-scrollbar-button { background: url(<!--path-->/img/_scrollTaxi.png) no-repeat 0 0; border: 2px solid #fff }
	|			div#content::-webkit-scrollbar-button:vertical { height: 23px }
	|			div#content::-webkit-scrollbar-button:horizontal { width: 23px }
	|			div#content::-webkit-scrollbar-button:vertical:start { background-position: -28px -1px }
	|			div#content::-webkit-scrollbar-button:vertical:end { background-position: -6px -1px }
	|			div#content::-webkit-scrollbar-button:horizontal:start { background-position: -1px -24px }
	|			div#content::-webkit-scrollbar-button:horizontal:end { background-position: -22px -24px }
	|			div#content::-webkit-scrollbar-button:vertical:start, div#content::-webkit-scrollbar-button:vertical:end, div#content::-webkit-scrollbar-button:horizontal:start, div#content::-webkit-scrollbar-button:horizontal:end { background-color: #c2c2c2 }
	|			div#content::-webkit-scrollbar-button:vertical:start:hover, div#content::-webkit-scrollbar-button:vertical:end:hover, div#content::-webkit-scrollbar-button:horizontal:start:hover, div#content::-webkit-scrollbar-button:horizontal:end:hover { background-color: #202020 }
	|		</style>
	|		<script type='text/javascript'>function scrollBottom(){foundElement = document.getElementById('content'); foundElement.scrollTo(0,foundElement.scrollHeight);}</script>
	|		<!--script_place-->
	|	</head>
	|	<body onload='scrollBottom()'>
	|		<div id='content'>
	|			<div id='comments' class='width100'>
	|				<!--comments_place-->
	|			</div>
	|			<div id='nav' class='hidden'>
	|			    <p>Непрочитанные комментарии</p>
	|			    <ul>
	|					<!--navcomment_place-->
	|			    </ul>
	|			</div>
	|		</div>
	|	</body>
	|</html>", "<!--path-->", WebОкружениеВызовСервера.АдресПубликацииСлужебныхДанных());
	
	Результат.ОбластьКомментариев = 
	"				<!--comment_place-->
	|				<div id='comments_panel'>
	|					<a href='sdms_action=add'>Добавить</a>
	|					<a href='sdms_action=refresh'>Обновить</a>
	|				</div>";
	
	Результат.Комментарий = 
	"<div class='comment'>
	|	<div id='<!--comment_id-->' class='<!--comment_type--> transition'>
	|		<div class=""profile_image""></div>
	|		<h1><!--comment_privateMassage--><!--comment_author-->&nbsp;<span class='date' <!--comment_date_title-->><!--comment_date--><!--comment_answer--></span><span class='comment_object'><!--comment_object--></span></h1>
	|		<div class='comment_body'>
	|			<div class='comment_body_text'>
	|				<p><span><!--comment_text--></span></p>
	|			</div>
	|			<!--comment_body_panel_item-->
	|		</div>
	|	</div>
	|	<div class='comment_child' id='<!--comment_child_id-->'>
	|		<!--comment_child-->
	|	</div>
	|</div>
	|<!--comment_place-->";
	
	Результат.КомментарийНавигации =
	"<li id='link_comment_%1' onclick='ScrollToElement(this.id)'>%2 %3</li>";
	
	Результат.ПросмотренныйКомментарийНавигации =
	"<li id='link_comment_%1' class='visited' onclick='ScrollToElement(this.id)'>%2 %3</li>";
	
	Результат.Ссылка_Ответить = "<span class='comment_body_panel'><a href='<!--comment_link_answer-->'><span class='answerImage'></span>Ответить</a></span><!--comment_body_panel_item-->";
	Результат.Ссылка_СвернутьВетку = "<span class='comment_body_panel'><a href='<!--comment_link_toggleChildVisible-->' id='<!--link_toggleChildVisible_id-->'><span class='collapseImage'></span>Свернуть ветку</a></span><!--comment_body_panel_item-->";
	Результат.Ссылка_Изменить = "<span class='comment_body_panel'><a href='<!--comment_link_edit-->'><span class='editImage'></span>Изменить</a></span><!--comment_body_panel_item-->";
	Результат.Ссылка_Удалить = "<span class='comment_body_panel'><a href='<!--comment_link_delete-->'><span class='deleteImage'></span>Удалить</a></span><!--comment_body_panel_item-->";
	Результат.Ссылка_ОтметитьВажным = "<span class='comment_body_panel'><a href='<!--comment_link_togglePriority-->' id='<!--comment_link_togglePriority_id-->'><span class='togglePriorityImage'></span><!--comment_link_togglePriority_title--></a></span><!--comment_body_panel_item-->";
	Результат.Ссылка_ОткрытьВНовомОкне = "<a title='Открыть в новом окне' href='%1' target='_blank'>%2</a>";

	Результат.Ссылка_Скопировать = 		
	"<a href='sdms_action=copyLink&link=%1'>
	|	<img class='copy_img' src='data:image/jpg;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QA/wD/AP+gvaeTAAAA5UlEQVQ4jaXTPUoDURQF4C+ihKQxakCwSqezE1FsRItZQkCLZB1OoxaWYiMWWgQEt2HlClyACNYW7waHQZ0Xcsrz7rn33J/HkugsEHuCQ3zhGm+LFKlwhlVs4QFFboILlA1uGC6stIiP8I77Bv+Bfk71GwywiW6NP8dxjoNXbOMWveBKjPD0l+gAVxhjBzPshZOpNJNft9eJxwnWQzSLJGNcYv8/u5WfaW+EeDfErTiV9jxHN5IMop1W3ElH0sRUi+35Fj6jWh2l1P9LjoNCOs8h1qQ9VzL+Sj2gkObQwzMecyovjW+DPR87cOijXQAAAABJRU5ErkJggg=='>
	|</a>";	
		
	Возврат Результат;
	
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Функция ПолучитьВысшегоРодителя(Знач Родитель)
	
	Запрос = Новый запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ ПЕРВЫЕ 1
	|	СвязиКомментариев.ВысшийРодитель КАК ВысшийРодитель
	|ИЗ
	|	РегистрСведений.СвязиКомментариев КАК СвязиКомментариев
	|ГДЕ
	|	СвязиКомментариев.Подчиненный = &Родитель";
	
	Запрос.УстановитьПараметр("Родитель", Родитель);
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Выборка.Следующий() Тогда	
		ВысшийРодитель = Выборка.ВысшийРодитель;
	Иначе
		ВысшийРодитель = Родитель;
	КонецЕсли;
	
	Возврат ВысшийРодитель;
	
КонецФункции

#КонецОбласти

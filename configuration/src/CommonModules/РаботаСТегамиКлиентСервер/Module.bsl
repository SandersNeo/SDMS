///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, ООО ДНС Технологии
// SDMS (Software Development Management System) — это корпоративная система учета разработки и управления проектами 
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии General Public License (GNU GPL v3)
// Текст лицензии доступен по ссылке:
// https://www.gnu.org/licenses/gpl-3.0.html
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Область ПрограммныйИнтерфейс

// Представление тегов в формате html
//
// Параметры:
//  СписокТегов		 - ТаблицаЗначений	 - Таблица с данными тегов объекта
//  ДобавлениеТегов	 - Булево			 - Истина, если нажатие из формы добавления тегов, иначе Ложь
//  Цвет			 - Цвет, ЦветСтиля	 - Цвет фона тега
// 
// Возвращаемое значение:
//  Строка - представление тегов в html
//
Функция ПредставлениеТегов(Знач СписокТегов, Знач ДобавлениеТегов = Ложь, Знач Цвет = Неопределено) Экспорт
	
	АдресПубликации = WebОкружениеВызовСервера.АдресПубликацииСлужебныхДанных();	
	
	ШаблонТега = ШаблонТега(ДобавлениеТегов);
	ШаблонСпискаТегов = ШаблонСпискаТегов(ДобавлениеТегов, Цвет);
		
	МассивТегов = Новый Массив;
	
	Для Каждого Элемент Из СписокТегов Цикл
		Если Элемент.Отвязать Тогда
			Продолжить;
		КонецЕсли;
		
		ТекстТега = СтрШаблон(ШаблонТега, Элемент.Идентификатор, Элемент.ТегПредставление);
		МассивТегов.Добавить(ТекстТега);
	КонецЦикла;
	
	ТегиHTML = СтрСоединить(МассивТегов);	
	ТегиHTML = СтрШаблон(ШаблонСпискаТегов, АдресПубликации, ТегиHTML);
	
	Возврат ТегиHTML;
	
КонецФункции

// Шаблон html тега
//
// Параметры:
//  Переносить - Булево - Истина, если нужно добавить перенос после тега, иначе Ложь 
// 
// Возвращаемое значение:
//   Строка - Шаблон html тега 
//
Функция ШаблонТега(Знач Переносить = Ложь) Экспорт
	
	Шаблон = "<div class='tag'><a href='Tag_%1'>%2</a><a class='del' href='DeleteTag_%1'>&#215;</a></div>";
	
	Если Переносить Тогда
		Шаблон = СтрШаблон("%1</br>", Шаблон);
	КонецЕсли;
			
	Возврат Шаблон;
	
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Функция ШаблонСпискаТегов(Знач ДобавлениеТегов, Знач Цвет)
	
	Если ДобавлениеТегов Тогда
		ЦветФона = "#fff";
		ШаблонКнопки = "";
	Иначе
		Если Цвет = Неопределено Тогда
			ЦветФона = "#F0F8FF";
		Иначе
			ЦветФона = "#" + Врег(ОбщегоНазначенияКлиентСервер.ПолучитьHexКодЦвета(Цвет));
		КонецЕсли;
		
		ШаблонКнопки = "<div id='' class='add'><a href='add'><div class='addImg'></div>Добавить</a></div>";
	КонецЕсли;
		
	Шаблон = 
	"<!DOCTYPE HTML>
	|<html lang='en'>
	|	<head>
	|		<meta charset='UTF-8'>
	|		<title></title>
	|		<style>
	|			* { margin: 0; padding: 0; }
	|			body { overflow: hidden; }
	|			div.body { background: " + ЦветФона + "; overflow-y: auto; height: 100%%; }
	|			.tag { display: inline-block; background: #eee; padding: 5px 8px; border-radius: 25px; margin: 0px 2px 4px; font-family: sans-serif; font-size: .8em; transition: background 0.3s ease-in; }
	|			.tag:hover { background: #dedede; }
	|			a { text-decoration: none; color: black; }
	|			a.del { margin-left: 4px; font-size: 1em; }
	|			a:hover { text-decoration: underline; }
	|			a.del:hover { text-decoration: none; }
	|			.add { display: inline-block; font-family: sans-serif; font-size: .8em; height: 16px; padding: 5px 5px; }
	|			.add a { vertical-align: middle; height: 16px; }
	|			.addImg { display: inline-block; width: 16px; height: 16px; margin-bottom: -3px; margin-right: 4px; background-position: 0 0; background-repeat: no-repeat; background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABsUlEQVQ4jZ2TPUscURSGn7tMFtyPa2RcHLXYZtakWru1Mf8gsdHUkrQSCLbCgkKKVNGQkCqCaYON4D+wMVWwkjgIK6zMJjssTGYmskvupJhxMruzBOIpX8597nvOfa8ACMOQu5Y2Ksid+WlgE3gMLMTyOXAEvHWb7W66X6QdyJ35VeCjWTUnZysGxYkiAF7gY3dtrJblAs/dZvswA4gPf16qN4Q+pY+16/QcTs++hMDTW4gAKG/PVQBrqd6Q6cMHy+8BWD/ZGIW4QM1ttr/nYv1FrWrK0Zu1nIaWG16TPqVTq5oSeAlwC1iZmTYylvtqQF8NMrpRMSBacvIKD0uFYmJbiIibz90D4NOjDwCEoWL9ZINi1PsgDUjq0rtCiwFzhcjVddBBCPitVARSIUA/DTj3An9Rlspsf32dwLbqm0DIq7M3Q5cENwHAZXoHR52unZlV5svIvMzo9g8b4DgNeHfRslyn5ww1egMfb+APaU7P4SIK1C6MC9JiQ+j3/zNIqSivAftm1SzPVgxKhRJKKfxfPna3g9WyfgLPxkY5mfvvZ3pC9FR94Fs8894/P9Nd6g/iT7J5V+tghwAAAABJRU5ErkJggg=='); }
	|
	|			div.body::-webkit-scrollbar { width: 12px; height: 12px }
	|			div.body::-webkit-scrollbar-track,
	|			div.body::-webkit-scrollbar-thumb { border-radius: 5px; border-style: solid; border-color: " + ЦветФона + " }
	|			div.body::-webkit-scrollbar-track { background: #d6d6d6 }
	|			div.body::-webkit-scrollbar-thumb { background: #9a9a9a }
	|			div.body::-webkit-scrollbar-track:horizontal,
	|			div.body::-webkit-scrollbar-thumb:horizontal { border-width: 2px 0 }
	|			div.body::-webkit-scrollbar-track:vertical,
	|			div.body::-webkit-scrollbar-thumb:vertical { border-width: 0 2px }
	|			div.body::-webkit-scrollbar-thumb:hover { background: #757575 }
	|			div.body::-webkit-scrollbar-button { background: url(%1/img/_scrollTaxi_.png) no-repeat 0 0; border: 2px solid " + ЦветФона + " }
	|			div.body::-webkit-scrollbar-button:vertical { height: 23px }
	|			div.body::-webkit-scrollbar-button:horizontal { width: 23px }
	|			div.body::-webkit-scrollbar-button:vertical:start { background-position: -28px -1px }
	|			div.body::-webkit-scrollbar-button:vertical:end { background-position: -6px -1px }
	|			div.body::-webkit-scrollbar-button:horizontal:start { background-position: -1px -24px }
	|			div.body::-webkit-scrollbar-button:horizontal:end { background-position: -22px -24px }
	|			div.body::-webkit-scrollbar-button:vertical:start,
	|			div.body::-webkit-scrollbar-button:vertical:end,
	|			div.body::-webkit-scrollbar-button:horizontal:start,
	|			div.body::-webkit-scrollbar-button:horizontal:end { background-color: " + ЦветФона + " }
	|			div.body::-webkit-scrollbar-button:vertical:start:hover,
	|			div.body::-webkit-scrollbar-button:vertical:end:hover,
	|			div.body::-webkit-scrollbar-button:horizontal:start:hover,
	|			div.body::-webkit-scrollbar-button:horizontal:end:hover { background-color: " + ЦветФона + " }
	|		</style> 
	|	</head>
	|	<body>
	|		<div class='body'>
	|			%2
	|			" + ШаблонКнопки + "
	|		</div></body>
	|</html>";
	
	Возврат Шаблон;
		
КонецФункции

#КонецОбласти

///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, ООО ДНС Технологии
// SDMS (Software Development Management System) — это корпоративная система учета разработки и управления проектами 
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии General Public License (GNU GPL v3)
// Текст лицензии доступен по ссылке:
// https://www.gnu.org/licenses/gpl-3.0.html
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Область ПрограммныйИнтерфейс

Функция ШаблонВнЗадания() Экспорт
	
	// Параметры шаблона:
	// <!--taskGUID-->		- GUID ссылки задачи		 - уникальный идентификатор без разделителей
	// <!--statusImage-->	- Картинка статуса			 - путь к картинке
	// <!--statusPreview-->	- Представление статуса		 - название статуса
	// <!--taskLink-->		- Ссылка на задачу			 - внешняя ссылка на задачу
	// <!--taskPreview-->	- Представление задачи		 - строка формата "12345. Тема задачи"
	// <!--activityRow-->	- Действия по задаче		 - строки таблицы с активностями по задаче
	// <!--timeWasteRow-->	- Трудозатрат задачи		 - строки таблицы с занесенными трудозатратами
	// <!--timeWastePlan-->	- Плановые трудозатраты		 - количество плановых трудозатрат
	// <!--timeWasteFact-->	- Фактические трудозатраты	 - количество фактических трудозатрат
	
	Шаблон = 
	"<tr id=""taskRow_<!--taskGUID-->"">
	|	<td>
	|		<tr>
	|			<td class=""status""><span class=""image""><img src=""<!--statusImage-->""></span><!--statusPreview--></td>
	|			<td class=""task""><a href=""<!--taskLink-->""><!--taskPreview--></a></td>
	|		</tr>
	|		<tr>
	|			<td class=""firstColumn"">Трудозатраты</td>
	|			<td>
	|				<table id=""timeWasteTable_<!--taskGUID-->"">
	|					<tr>
	|						<td class=""action""><span class=""taskTimeWaste"">План: <!--timeWastePlan--></span><span class=""taskTimeWaste"">Факт: <!--timeWasteFact--></span></td>
	|					</tr>
	|					<!--timeWasteRow-->
	|				</table>
	|			</td>
	|		</tr>
	|		<tr><td class=""divider""></td></tr>
	|	</td>
	|</tr>
	|<!--taskRow-->";
	
	Возврат Шаблон;
	
КонецФункции

Функция ШаблонЗадачи() Экспорт
	
	// Параметры шаблона:
	// <!--taskGUID-->		- GUID ссылки задачи		 - уникальный идентификатор без разделителей
	// <!--statusImage-->	- Картинка статуса			 - путь к картинке
	// <!--statusPreview-->	- Представление статуса		 - название статуса
	// <!--taskLink-->		- Ссылка на задачу			 - внешняя ссылка на задачу
	// <!--taskPreview-->	- Представление задачи		 - строка формата "12345. Тема задачи"
	// <!--activityRow-->	- Действия по задаче		 - строки таблицы с активностями по задаче
	// <!--timeWasteRow-->	- Трудозатрат задачи		 - строки таблицы с занесенными трудозатратами
	// <!--timeWastePlan-->	- Плановые трудозатраты		 - количество плановых трудозатрат
	// <!--timeWasteFact-->	- Фактические трудозатраты	 - количество фактических трудозатрат
	
	Шаблон = 
	"<tr id=""taskRow_<!--taskGUID-->"">
	|	<td>
	|		<tr>
	|			<td class=""status""><span class=""image""><img src=""<!--statusImage-->""></span><!--statusPreview--></td>
	|			<td class=""task""><a href=""<!--taskLink-->""><!--taskPreview--></a></td>
	|		</tr>
	|		<tr>
	|			<td class=""firstColumn"">Активности</td>
	|			<td>
	|				<table id=""activityTable_<!--taskGUID-->"">
	|					<!--activityRow-->
	|				</table>
	|			</td>
	|		</tr>
	|		<tr>
	|			<td class=""firstColumn"">Трудозатраты</td>
	|			<td>
	|				<table id=""timeWasteTable_<!--taskGUID-->"">
	|					<tr>
	|						<td class=""action""><span class=""taskTimeWaste"">План: <!--timeWastePlan--></span><span class=""taskTimeWaste"">Факт: <!--timeWasteFact--></span></td>
	|					</tr>
	|					<!--timeWasteRow-->
	|				</table>
	|			</td>
	|		</tr>
	|		<tr><td class=""divider""></td></tr>
	|	</td>
	|</tr>
	|<!--taskRow-->";
	
	Возврат Шаблон;
	
КонецФункции

Функция ШаблонЗаявки() Экспорт
	
	// Параметры шаблона:
	// <!--taskGUID-->		- GUID ссылки задачи		 - уникальный идентификатор без разделителей
	// <!--statusImage-->	- Картинка статуса			 - путь к картинке
	// <!--statusPreview-->	- Представление статуса		 - название статуса
	// <!--taskLink-->		- Ссылка на задачу			 - внешняя ссылка на задачу
	// <!--taskPreview-->	- Представление задачи		 - строка формата "12345. Тема задачи"
	// <!--activityRow-->	- Действия по задаче		 - строки таблицы с активностями по задаче
	// <!--timeWasteRow-->	- Трудозатрат задачи		 - строки таблицы с занесенными трудозатратами
	// <!--timeWastePlan-->	- Плановые трудозатраты		 - количество плановых трудозатрат
	// <!--timeWasteFact-->	- Фактические трудозатраты	 - количество фактических трудозатрат
	
	Шаблон = 
	"<tr id=""taskRow_<!--taskGUID-->"">
	|	<td>
	|		<tr>
	|			<td class=""status""><span class=""image""><img src=""<!--statusImage-->""></span><!--statusPreview--></td>
	|			<td class=""task""><a href=""<!--taskLink-->""><!--taskPreview--></a></td>
	|		</tr>
	|		<tr>
	|			<td class=""firstColumn"">Активности</td>
	|			<td>
	|				<table id=""activityTable_<!--taskGUID-->"">
	|					<!--activityRow-->
	|				</table>
	|			</td>
	|		</tr>
	|		<tr>
	|			<td class=""firstColumn"">Трудозатраты</td>
	|			<td>
	|				<table id=""timeWasteTable_<!--taskGUID-->"">
	|					<tr>
	|						<td class=""action""><span class=""taskTimeWaste"">Факт: <!--timeWasteFact--></span></td>
	|					</tr>
	|					<!--timeWasteRow-->
	|				</table>
	|			</td>
	|		</tr>
	|		<tr><td class=""divider""></td></tr>
	|	</td>
	|</tr>
	|<!--taskRow-->";
	
	Возврат Шаблон;
	
КонецФункции

Функция ШаблонСтраницы() Экспорт
	
	// Параметры шаблона:
	// <!--taskRow-->				 - строки задач
	// <!--todayTimeWastePlan-->	 - плановые трудозатраты
	// <!--todayTimeWasteFact-->	 - фактические трудозатраты
	// <!--classPlace-->			 - строка класса если факт меньше плана (class="redText")
	// <!--todayPreview-->			 - представление дня
	
	Шаблон = 
	"<!DOCTYPE HTML>
	|<html lang=""ru"">
	|	<head>
	|		<meta charset=""UTF-8"">
	|		<meta http-equiv=""X-UA-Compatible"" content=""IE=9""/>
	|		<title></title>
	|		<style>
	|			img { border: 1px solid white; margin: 0px; padding: 0px; }
	|			table {	margin: 0px; padding: 0px; }
	|			td, a, div { padding: 5px 20px 0px 0px; vertical-align: text-top; font-family: Verdana, Arial, sans-serif; }
	|			.firstColumn { font-weight: 600; color: dimgray; font-size: 12px; padding-left: 21px; }
	|			.status { font-size: 16px; font-weight: 600; width: 210px; }
	|			.task { color: #2c77ff; font-weight: 600; font-size: 16px; }
	|			.task a {text-decoration: none; color: inherit; }
	|			.action { color: dimgray; font-size: 12px; }
	|			.add { text-decoration: none; font-size: 12px; color: #2c77ff; font-style: italic; }
	|			.image { margin: 0px 5px 0px 0px; }
	|			.image12 { height: 12px; width: 12px; }
	|			.divider { padding: 10px; }
	|			.timeWaste { font-weight: 600; font-size: 14px; margin-left: 30px; color: dimgray; }
	|			.redText { color: rgb(250, 95, 95); }
	|			.timeWasteTitle { font-size: 18px; font-weight: 600; }
	|			.header { position: fixed; top: 0px; left: 0px; padding: 15px; width: 100%; background: white;}
	|			.content { margin-top: 35px; padding-bottom: 50px; }
	|			.taskTimeWaste { margin-right: 10px; font-weight: 600; }
	|		</style>
	|	</head>
	|	<body>
	|		<div class=""header"">
	|			<span class=""timeWasteTitle""><!--todayPreview--></span>
	|			<span class=""timeWaste"">Плановые трудозатраты: <!--todayTimeWastePlan--></span>
	|			<span class=""timeWaste <!--classPlace-->"" id=""totalTime"">Фактические трудозатраты: <!--todayTimeWasteFact--></span>
	|		</div>
	|		<div class=""content"">
	|			<table>
	|				<!--taskRow-->
	|			</table>
	|		</div>
	|	</body>
	|</html>";
	
	Возврат Шаблон;
	
КонецФункции

Функция Шаблоны() Экспорт
	
	Результат = Новый Структура;
	Результат.Вставить("ВнЗадание", ШаблонВнЗадания());
	Результат.Вставить("Задача", ШаблонЗадачи());
	Результат.Вставить("Заявка", ШаблонЗаявки());
	Результат.Вставить("Страница", ШаблонСтраницы());
	Результат.Вставить("Активности", ШаблоныАктивностей());
	Результат.Вставить("Трудозатраты", ШаблоныТрудозатрат());
	
	Возврат Результат;
	
КонецФункции

Функция ШаблоныАктивностей() Экспорт
	
	Результат = Новый Структура("Активность, ДобавитьВсеАктивности, АктивностьЗаявки, НетАктивности");
	
	// Параметры шаблона:
	// <!--GUID-->				- Идентификатор		 - произвольный идентификатор
	// <!--statusImage-->		- Картинка статуса	 - путь к картинке статуса
	// <!--statusTimePreview-->	- Статус и время	 - строка формата "В работе (2 ч. 15 мин.)"
	
	Результат.Активность = 
	"<tr id=""activity_<!--GUID-->"">
	|	<td class=""action""><span class=""image""><img class=""image12"" src=""<!--statusImage-->""></span><!--statusTimePreview--></td>
	|	<td><a href=""addActivity_<!--GUID-->"" class=""add"">+ Добавить</a></td>
	|</tr>";
		
	Результат.АктивностьЗаявки = 
	"<tr>
	|	<td class=""action""><!--ActivityText--></td>
	|</tr>";
	
	Результат.НетАктивности = 
	"<tr>
	|	<td class=""action"">За текущий день не было изменений статуса задачи.</td>
	|</tr>";
	
	Возврат Результат;
	
КонецФункции

Функция ШаблоныТрудозатрат() Экспорт
	
	Результат = Новый Структура("Трудозатрата, ДобавитьТрудозатраты");
	
	// Параметры шаблона:
	// <!--timeWasteDescription--> - описание трудозатраты
	
	Результат.Трудозатрата = 
	"<tr id=""timeWaste_<!--GUID-->"">
	|	<td class=""action""><!--timeWasteDescription--></td>
	|</tr>";
	
	// Параметры шаблона:
	// <!--taskGUID--> - идентификатор задачи
	
	Результат.ДобавитьТрудозатраты = 
	"<tr>
	|	<td><a href=""addTimeWaste_<!--taskGUID-->"" class=""add"">+ Добавить</a></td>
	|</tr>";
	
	Возврат Результат;
	
КонецФункции

#КонецОбласти

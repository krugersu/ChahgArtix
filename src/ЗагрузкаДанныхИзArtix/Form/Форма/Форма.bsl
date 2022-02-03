﻿
&НаСервере
Процедура ЗагрузитьКассовыеСменыНаСервере()
	
	НеФормироватьЧеки = Истина;
	
	//1. В начале отрабатываем изменения по текущим сменам, который уже есть в 1С
	
	// Получаем список всех не закрытых смен в 1С, в норме все смены кроме текущего и прошлого дня должны
	// быть закрыты
	СписокНеЗакрытыхКассовыхСмен = ПолучитьСписокНеЗакрытыхКассовыхСменВ1С();
	СписокИДЧековВСмене = Новый СписокЗначений;
	
	// Для каждой не закрытой смены делаем запрос к кассовому серверу и анализируем закрылась ли смена, если
	// да , то закрываем смену в 1С (возможно в будущем переделать запрос, что бы получать все смены одним запросом
	// используя в качестве параметра список номеров смен - СписокНеЗакрытыхКассовыхСмен)
	Для Каждого тСтрока из СписокНеЗакрытыхКассовыхСмен Цикл
		
		// Запрос на получение кассовой смены по номеру
		ЗапросКассоваяСменаПоНомеру = Новый Запрос;
		ЗапросКассоваяСменаПоНомеру.Текст = ВернутьТекстЗапросаКассоаяСменаПоНомеру();
		ЗапросКассоваяСменаПоНомеру.УстановитьПараметр("shiftnum", тСтрока.Значение);
		РезультатКассоваяСмена = ЗапросКассоваяСменаПоНомеру.Выполнить().Выгрузить();
		// Если смена закрыта в кассовом сервере, то закрываем ее в 1С
		Если НЕ РезультатКассоваяСмена.Количество() = 0 Тогда
			текКассоваяСмена = ЗакрытьКассовуюСмену(РезультатКассоваяСмена);
			// Попытка создания чеков при закрытии смены
			// Проверяем если вернулась ссылка на кассовую смену, то начинаем процедуру создания чеков
			Если текКассоваяСмена <> Неопределено Тогда
				// Формируем сразу ОРП чеки не загружаем
				Если  НеФормироватьЧеки Тогда
					
					
					
				Иначе // Загружаем чеки и потом на их основе формируем ОРП 
					СписокИДЧековВСмене.Очистить();
					ТаблицаШапкиЧеков = ЗагрузитьЧекиНаСервере(текКассоваяСмена.НомерСменыККТ);
					СписокИДЧековВСмене = ТаблицаШапкиЧеков.ВыгрузитьКолонку("documentid");
					ТаблицаТЧТовары = ЗагрузитьТЧТовары(СписокИДЧековВСмене);
					СоздатьЧеки(ТаблицаШапкиЧеков,текКассоваяСмена,ТаблицаТЧТовары,СписокИДЧековВСмене);
				КонецЕсли; 
			КонецЕсли; 
			
		КонецЕсли; 
		
	КонецЦикла;
	
	
	//2. Затем обрабатываем получение новых смен из кассового сервера 
	
	// Получаем дату первой незакрытой смены в 1С, для того что бы ограничить период запроса в кассовом сервере
	shiftnum = 14;
	ДатаПервойНеЗакрытойСмены = Неопределено;
	ДатаПервойНеЗакрытойСмены = ПолучитьДатуПервойНеЗакрытойСмены();
	Если ДатаПервойНеЗакрытойСмены = Неопределено Тогда
		ДатаПервойНеЗакрытойСмены = НачалоДня(ТекущаяДата());
	КонецЕсли;
	
	// Запрос на получение всех кассовых смен с определенной даты
	ЗапросКассовыеСмены = Новый Запрос;
	ЗапросКассовыеСмены.Текст = ВернутьТекстЗапросаКассовыеСмены();
	ЗапросКассовыеСмены.УстановитьПараметр("time_beg", ДатаПервойНеЗакрытойСмены);
	Результат = ЗапросКассовыеСмены.Выполнить().Выгрузить();
	
	
	// Функция по созданию и открытию документов Кассовая смена в 1С
	МассивКассовыеСмены = ОткрытьКассовуюСмену(Результат);
	
КонецПроцедуры

&НаКлиенте
Процедура ЗагрузитьКассовыеСмены(Команда)
	ЗагрузитьКассовыеСменыНаСервере();
КонецПроцедуры



// Формирует запрос по кассовым сменам
//
// Параметры:
//  <Параметр1>  - <Тип.Вид> - <описание параметра>
//                 <продолжение описания параметра>
//  <Параметр2>  - <Тип.Вид> - <описание параметра>
//                 <продолжение описания параметра>
//
// Возвращаемое значение:
//   <Тип.Вид>   - <описание возвращаемого значения>
//
Функция ВернутьТекстЗапросаКассовыеСмены()
	
	ТекстЗапроса = 
	"ВЫБРАТЬ
	|	workshift.workshiftid КАК workshiftid,
	|	workshift.storeId КАК storeId,
	|	workshift.shiftnum КАК shiftnum,
	|	workshift.cashcode КАК cashcode,
	|	workshift.cashId КАК cashId,
	|	workshift.scode КАК scode,
	|	workshift.time_beg КАК time_beg,
	|	workshift.time_end КАК time_end,
	|	workshift.checknum1 КАК checknum1,
	|	workshift.checknum2 КАК checknum2,
	|	workshift.vb КАК vb,
	|	workshift.vn КАК vn,
	|	workshift.ve КАК ve,
	|	workshift.mode1 КАК mode1,
	|	workshift.mode2 КАК mode2,
	|	workshift.arcpath КАК arcpath,
	|	workshift.shifttype КАК shifttype,
	|	workshift.dateincrement КАК dateincrement,
	|	workshift.shopcode КАК shopcode,
	|	workshift.changed КАК changed,
	|	workshift.sumSale КАК sumSale,
	|	workshift.sumGain КАК sumGain,
	|	workshift.sumDrawer КАК sumDrawer,
	|	workshift.version КАК version,
	|	workshift.postype КАК postype,
	|	workshift.revision КАК revision,
	|	workshift.firstchecktime КАК firstchecktime,
	|	workshift.update_time КАК update_time,
	|	workshift.sumsalecash КАК sumsalecash,
	|	workshift.sumsalenoncash КАК sumsalenoncash,
	|	workshift.sumsaleother КАК sumsaleother,
	|	workshift.sumgaincash КАК sumgaincash,
	|	workshift.sumgainnoncash КАК sumgainnoncash,
	|	workshift.sumrefund КАК sumrefund,
	|	workshift.sumrefundcash КАК sumrefundcash,
	|	workshift.sumrefundnoncash КАК sumrefundnoncash,
	|	workshift.countsale КАК countsale,
	|	workshift.countrefund КАК countrefund
	|ИЗ
	|	ВнешнийИсточникДанных.КассовыйСервер.Таблица.workshift КАК workshift
	|ГДЕ
	//	|	workshift.shiftnum = &shiftnum
	|	 workshift.time_beg > &time_beg";
	
	//Запрос.УстановитьПараметр("shiftnum", shiftnum);
	
	
	Возврат ТекстЗапроса;
	
КонецФункции // ВернутьТекстЗапросаКассовыеСмены()


// Формирует запрос по кассовой смене по номеру
//
// Параметры:
//  <Параметр1>  - <Тип.Вид> - <описание параметра>
//                 <продолжение описания параметра>
//  <Параметр2>  - <Тип.Вид> - <описание параметра>
//                 <продолжение описания параметра>
//
// Возвращаемое значение:
//   <Тип.Вид>   - <описание возвращаемого значения>
//
Функция ВернутьТекстЗапросаКассоаяСменаПоНомеру()
	
	ТекстЗапроса = 
	"ВЫБРАТЬ
	|	workshift.workshiftid КАК workshiftid,
	|	workshift.storeId КАК storeId,
	|	workshift.shiftnum КАК shiftnum,
	|	workshift.cashcode КАК cashcode,
	|	workshift.cashId КАК cashId,
	|	workshift.scode КАК scode,
	|	workshift.time_beg КАК time_beg,
	|	workshift.time_end КАК time_end,
	|	workshift.checknum1 КАК checknum1,
	|	workshift.checknum2 КАК checknum2,
	|	workshift.vb КАК vb,
	|	workshift.vn КАК vn,
	|	workshift.ve КАК ve,
	|	workshift.mode1 КАК mode1,
	|	workshift.mode2 КАК mode2,
	|	workshift.arcpath КАК arcpath,
	|	workshift.shifttype КАК shifttype,
	|	workshift.dateincrement КАК dateincrement,
	|	workshift.shopcode КАК shopcode,
	|	workshift.changed КАК changed,
	|	workshift.sumSale КАК sumSale,
	|	workshift.sumGain КАК sumGain,
	|	workshift.sumDrawer КАК sumDrawer,
	|	workshift.version КАК version,
	|	workshift.postype КАК postype,
	|	workshift.revision КАК revision,
	|	workshift.firstchecktime КАК firstchecktime,
	|	workshift.update_time КАК update_time,
	|	workshift.sumsalecash КАК sumsalecash,
	|	workshift.sumsalenoncash КАК sumsalenoncash,
	|	workshift.sumsaleother КАК sumsaleother,
	|	workshift.sumgaincash КАК sumgaincash,
	|	workshift.sumgainnoncash КАК sumgainnoncash,
	|	workshift.sumrefund КАК sumrefund,
	|	workshift.sumrefundcash КАК sumrefundcash,
	|	workshift.sumrefundnoncash КАК sumrefundnoncash,
	|	workshift.countsale КАК countsale,
	|	workshift.countrefund КАК countrefund
	|ИЗ
	|	ВнешнийИсточникДанных.КассовыйСервер.Таблица.workshift КАК workshift
	|ГДЕ
	|	workshift.shiftnum = &shiftnum
	|	И НЕ workshift.time_end ЕСТЬ NULL";
	
	//Запрос.УстановитьПараметр("shiftnum", shiftnum);
	
	
	Возврат ТекстЗапроса;
	
КонецФункции // ВернутьТекстЗапросаКассовыеСмены()



Функция ОткрытьКассовуюСмену(Результат)
	
	СсылкаНаКассовуюСмену = Документы.КассоваяСмена.ПустаяСсылка();
	
	МассивДокументовКассоваяСмена = Новый Массив; 
	
	Для каждого тСтрока Из Результат Цикл
		СтатасКассовойСмены = ?(тСтрока.time_end <> Null,Перечисления.СтатусыКассовойСмены.Закрыта,Перечисления.СтатусыКассовойСмены.Открыта);
		Если НЕ ПроверитьНаличиеКассовойСмены(тСтрока.shiftnum, тСтрока.cashcode,тСтрока.shopcode) Тогда
			
			СсылкаНаКассовуюСмену = Документы.КассоваяСмена.СоздатьДокумент();
			СсылкаНаКассовуюСмену.Дата = тСтрока.time_beg;
			СсылкаНаКассовуюСмену.ДатаСменыККТ  = тСтрока.time_beg;
			СсылкаНаКассовуюСмену.НомерСменыККТ = тСтрока.shiftnum;
			СсылкаНаКассовуюСмену.НачалоКассовойСмены = тСтрока.time_beg;
			СсылкаНаКассовуюСмену.Статус = СтатасКассовойСмены;
			// СсылкаНаКассовуюСмену.Статус = Перечисления.СтатусыКассовойСмены.Закрыта;
			
			СсылкаНаКассовуюСмену.ФискальноеУстройство = Справочники.ПодключаемоеОборудование.НайтиПоНаименованию("'ШТРИХ-М:ККТ с передачей данных в ОФД (ФФД 1.2)' на <<Пользователь>>(gg51-54-cu)");
			
			СсылкаНаКассовуюСмену.КоличествоЧеков = тСтрока.countsale + тСтрока.countrefund;
			
			СсылкаНаКассовуюСмену.ОкончаниеКассовойСмены = тСтрока.time_end;  // Перенести в закрытие смены
			
			Попытка
				СсылкаНаКассовуюСмену.Записать(РежимЗаписиДокумента.Проведение);
			Исключение
			КонецПопытки;
			
			МассивДокументовКассоваяСмена.Добавить(СсылкаНаКассовуюСмену);
		КонецЕсли;
	КонецЦикла;  
	
	
	
	Возврат СсылкаНаКассовуюСмену;
КонецФункции	


// Проверяет существует ли документ кассовая сманеа по этой кассе за текущее время
Функция ПроверитьНаличиеКассовойСмены(НомерСмены,Касса,Магазин)
	
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	КассоваяСмена.Ссылка КАК Ссылка
	|ИЗ
	|	Документ.КассоваяСмена КАК КассоваяСмена
	|ГДЕ
	|	КассоваяСмена.НомерСменыККТ = &НомерСменыККТ";
	
	Запрос.УстановитьПараметр("НомерСменыККТ", НомерСмены);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Возврат ВыборкаДетальныеЗаписи.Следующий();	
	
	
	
КонецФункции	


// Возвращает дату первой незакрытой смены в 1С, для ограничения выборки из Кассового сервера
//
// Возвращаемое значение:
//   Дата или Неопределено - Дата первого незакрытого документа Кассовая смена или НЕопределено если таковой не найдено
Функция ПолучитьДатуПервойНеЗакрытойСмены()
	
	Статус = Перечисления.СтатусыКассовойСмены.Открыта;
	РезультатДата = Неопределено;
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ ПЕРВЫЕ 1
	|	КассоваяСмена.Ссылка КАК Ссылка,
	|	КассоваяСмена.Дата КАК Дата
	|ИЗ
	|	Документ.КассоваяСмена КАК КассоваяСмена
	|ГДЕ
	|	КассоваяСмена.Статус = &Статус
	|
	|УПОРЯДОЧИТЬ ПО
	|	КассоваяСмена.Дата";
	
	Запрос.УстановитьПараметр("Статус", Статус);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Если ВыборкаДетальныеЗаписи.Следующий() Тогда
		РезультатДата = ВыборкаДетальныеЗаписи.Дата;
	КонецЕсли;;
	
	Возврат РезультатДата;
	
КонецФункции // ПолучитьДатуПервойНеЗакрытойСмены()


// Возвращает список содержащий ссылки на все незакрытые кассовые смены в 1С
// Предпологается, что данные по закрытым сменам не изменны и не рубуют корректировки
//
// Возвращаемое значение:
//   СписокЗначений  - Список значений содержащий ссылки на не закрытые документы кассовой смены
//
Функция ПолучитьСписокНеЗакрытыхКассовыхСменВ1С()
	
	
	СписокКассовыхСмен = Новый СписокЗначений;
	Статус = Перечисления.СтатусыКассовойСмены.Открыта;
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	КассоваяСмена.НомерСменыККТ КАК НомерСменыККТ
	|ИЗ
	|	Документ.КассоваяСмена КАК КассоваяСмена
	|ГДЕ
	|	КассоваяСмена.Статус = &Статус
	|
	|УПОРЯДОЧИТЬ ПО
	|	КассоваяСмена.Дата";
	
	Запрос.УстановитьПараметр("Статус", Статус);
	
	РезультатЗапроса = Запрос.Выполнить().Выгрузить();
	
	СписокКассовыхСмен.ЗагрузитьЗначения(РезультатЗапроса.ВыгрузитьКолонку("НомерСменыККТ"));
	
	Возврат СписокКассовыхСмен;
	
КонецФункции // ПолучитьСписокНеЗакрытыхКассовыхСменВ1С()


// В функции происходит попытка закрытия кассовой смены, если документ не найден , то возвращается Неопределено
&НаСервере
Функция ЗакрытьКассовуюСмену(РезультатКассоваяСмена);
	
	Результат = Неопределено;
	
	ТекущаяКассоваяСмена = Документы.КассоваяСмена.НайтиПоРеквизиту("НомерСменыККТ",РезультатКассоваяСмена[0].shiftnum);
	
	Если НЕ ТекущаяКассоваяСмена = Документы.КассоваяСмена.ПустаяСсылка() Тогда
		ОбектТекущаяКассоваяСмена = ТекущаяКассоваяСмена.ПолучитьОбъект();
		ОбектТекущаяКассоваяСмена.ОкончаниеКассовойСмены = РезультатКассоваяСмена[0].time_end;
		// TODO Разобраться с реквизитами количества чеков
		// countrefund	int(11)	Количество чеков возврата
		//	countsale	int(11)	Количество чеков продажи
		// КоличествоФД   что сюда?
		// КоличествоЧеков что сюда?	
		// TODO заполнять кассу и организацию
		ОбектТекущаяКассоваяСмена.КоличествоЧеков = РезультатКассоваяСмена[0].countsale;
		ОбектТекущаяКассоваяСмена.Статус = Перечисления.СтатусыКассовойСмены.Закрыта;
		Попытка
			ОбектТекущаяКассоваяСмена.Записать(РежимЗаписиДокумента.Проведение);
			Результат = ТекущаяКассоваяСмена;  
		Исключение
			
		КонецПопытки;
		
	КонецЕсли; 
	Возврат Результат;
	
КонецФункции	

&НаСервере
Функция ЗагрузитьЧекиНаСервере(тНомерСмены)
	
	// Получить чеки  по номеру смены и коду кассы
	
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	document.documentid КАК documentid,
	|	document.cashcode КАК cashcode,
	|	document.workshiftid КАК workshiftid,
	|	document.checknum КАК checknum,
	|	document.doctype КАК doctype,
	|	document.dept КАК dept,
	|	document.scode КАК scode,
	|	document.time_beg КАК time_beg,
	|	document.time_end КАК time_end,
	|	document.vbrate КАК vbrate,
	|	document.verate КАК verate,
	|	document.sum1 КАК sum1,
	|	document.sum2 КАК sum2,
	|	document.sum2m КАК sum2m,
	|	document.summode КАК summode,
	|	document.sumtype КАК sumtype,
	|	document.disc_perc КАК disc_perc,
	|	document.disc_abs КАК disc_abs,
	|	document.sumb КАК sumb,
	|	document.sumn КАК sumn,
	|	document.sume КАК sume,
	|	document.vatsum КАК vatsum,
	|	document.docnum КАК docnum,
	|	document.c_link КАК c_link,
	|	document.closed КАК closed,
	|	document.opid КАК opid,
	|	document.dateincrement КАК dateincrement,
	|	document.buttonid КАК buttonid,
	|	document.linkeddocumentid КАК linkeddocumentid,
	|	document.departmentid КАК departmentid,
	|	document.clientitemid КАК clientitemid,
	|	document.changed КАК changed,
	|	document.rtext КАК rtext,
	|	document.sumcash КАК sumcash,
	|	document.identifier КАК identifier,
	|	document.url_egais КАК url_egais,
	|	document.digital_signature_egais КАК digital_signature_egais,
	|	document.update_time КАК update_time,
	|	document.actorcode КАК actorcode,
	|	document.moneyouttype КАК moneyouttype,
	|	document.nopdfUrlEgais КАК nopdfUrlEgais,
	|	document.nopdfDigitalSignatureEgais КАК nopdfDigitalSignatureEgais,
	|	document.customeraddress КАК customeraddress,
	|	document.closewithoutprint КАК closewithoutprint,
	|	document.sourceidentifier КАК sourceidentifier,
	|	document.frdocnum КАК frdocnum,
	|	document.frdoccopy КАК frdoccopy,
	|	document.backreason КАК backreason,
	|	document.fiscalidentifier КАК fiscalidentifier,
	|	document.correctionsourcedocnum КАК correctionsourcedocnum,
	|	document.correctionsourcedocdate КАК correctionsourcedocdate,
	|	document.correctionreason КАК correctionreason,
	|	document.correctiontype КАК correctiontype,
	|	document.waybillprinted КАК waybillprinted,
	|	document.waybillnumber КАК waybillnumber,
	|	document.sumnoncash КАК sumnoncash,
	|	document.sumother КАК sumother
	|ИЗ
	|	ВнешнийИсточникДанных.КассовыйСервер.Таблица.document КАК document
	|ГДЕ
	|	document.workshiftid = &workshiftid
	|	И document.cashcode = &cashcode";
	
	// TODO Передавать параметр код кассы в запрос отбора чеков
	Запрос.УстановитьПараметр("cashcode", "9999");
	Запрос.УстановитьПараметр("workshiftid", тНомерСмены);
	
	РезультатЗапроса = Запрос.Выполнить().Выгрузить();
	
	Возврат РезультатЗапроса;
	
КонецФункции
&НаКлиенте
Процедура ЗагрузитьЧеки(Команда)
	ЗагрузитьЧекиНаСервере(20);
КонецПроцедуры


// <Описание функции>
//
// Параметры:
//  <Параметр1>  - <Тип.Вид> - <описание параметра>
//                 <продолжение описания параметра>
//  <Параметр2>  - <Тип.Вид> - <описание параметра>
//                 <продолжение описания параметра>
//
// Возвращаемое значение:
//   <Тип.Вид>   - <описание возвращаемого значения>
//
Функция СоздатьЧеки(ТаблицаШапкиЧеков,текКассоваяСмена,ТаблицаТЧТовары,СписокИДЧековВСмене);
	
	//  TODO Добавить проверку на то, что чеки уже существует
	
	
	//Построитель = Новый ПостроительЗапроса;
	//Построитель.ИсточникДанных = Новый ОписаниеИсточникаДанных(ТаблицаТЧТовары);
	//
	//  
	//тОтбор = Построитель.Отбор.Добавить("documentid");
	//тОтбор.ВидСравнения = ВидСравнения.Равно;
	//тОтбор.Значение = НомераДокумента;
	//тОтбор.Использование = Истина;
	//
	//Построитель.Выполнить();
	//Товары = Построитель.Результат.Выгрузить();
	
	Для  Каждого текЧек из ТаблицаШапкиЧеков  Цикл
		Если НЕ текЧек.doctype = 13 Тогда
			
			НовыйЧек = Документы.ЧекККМ.СоздатьДокумент();
			НовыйЧек.Валюта = Справочники.Валюты.НайтиПоКоду("643");
			НовыйЧек.Дата = текЧек.time_beg;
			НовыйЧек.КассоваяСмена = текКассоваяСмена;
			НовыйЧек.Комментарий = "Сформирован обработкой загрузки из Artix - " + ТекущаяДата(); 
			//НовыйЧек.Номер = текЧек.checknum;
			НовыйЧек.Статус = Перечисления.СтатусыЧековККМ.Пробит;
			НовыйЧек.СуммаДокумента = текЧек.sumb;
			// TODO сделать поиск кассККМ
			НовыйЧек.КассаККМ = Справочники.КассыККМ.НайтиПоНаименованию("02_№1 (Главная) Гребенщикова 2");	
			// TODO Сделать поиск организации при формировании чекаККМ
			НовыйЧек.Организация = Справочники.Организации.НайтиПоНаименованию("Индивидуальный предприниматель Скрипникова Ольга Александровна");
			// TODO Сделать поиск склада при формировании чекаККМ
			НовыйЧек.Склад = Справочники.Склады.НайтиПоНаименованию("13.SKГребенщикова 2");     
			// TODO Сделать поиск вида цены при формировании чекаККМ
			НовыйЧек.ВидЦены = Справочники.ВидыЦен.НайтиПоНаименованию("13.SKГребенщикова 2");
			
			Отбор = Новый Структура();
			Отбор.Вставить("documentid",текЧек.documentid);
			
			Товары = ТаблицаТЧТовары.НайтиСтроки(Отбор);
			
			Для каждого тСтрока Из Товары Цикл
				
				нСтрока = НовыйЧек.Товары.Добавить();
				нСтрока.Номенклатура = Справочники.Номенклатура.НайтиПоКоду(тСтрока.code);
				нСтрока.Количество = тСтрока.bquant;
				нСтрока.КоличествоУпаковок = тСтрока.bquant;
				
				нСтрока.Цена = тСтрока.price;
				// TODO переделать на вызов стандартной процедуры пересчета строки ТЧ
				
				нСтрока.Сумма = нСтрока.Количество * нСтрока.Цена;
				нСтрока.Продавец = Справочники.Пользователи.НайтиПоНаименованию("Кассир");
				
				// TODO Ставка НДС в строке чека
				нСтрока.СтавкаНДС = Справочники.СтавкиНДС.БезНДС;
				
			КонецЦикла; 
			
			Попытка
				
				НовыйЧек.Записать(РежимЗаписиДокумента.Проведение);
				
			Исключение
				НовыйЧек.Записать(РежимЗаписиДокумента.Запись);
				
				// TODO Переделать все сообщения об ошибках в записи журнала регистрации
				
				Инфо = ИнформацияОбОшибке();
				Сообщить(НСтр("ru='Описание=';en='Description='") + Инфо.Описание + "'");
				Сообщить(НСтр("ru='ИмяМодуля=';en='ModuleName='") + Инфо.ИмяМодуля + "'");
				Сообщить(НСтр("ru='НомерСтроки=';en='LineNumber='") + Инфо.НомерСтроки + "'");
				Сообщить(НСтр("ru='ИсходнаяСтрока=';en='SourceLine='") + Инфо.ИсходнаяСтрока + "'");
			КонецПопытки;
			// TODO Уточнить про параметр ЦенаВключаетНДС
			//НовыйЧек.ЦенаВключаетНДС = Истина?
		КонецЕсли;
		
	КонецЦикла; 
	
	
	
	
КонецФункции //СоздатьЧеки(ТаблицаШапкиЧеков)




// <Описание функции>
//
// Параметры:
//  <Параметр1>  - <Тип.Вид> - <описание параметра>
//                 <продолжение описания параметра>
//  <Параметр2>  - <Тип.Вид> - <описание параметра>
//                 <продолжение описания параметра>
//
// Возвращаемое значение:
//   <Тип.Вид>   - <описание возвращаемого значения>
//
Функция ПолучитьТЧТоварыЧнкаККМ()
	
	
	
КонецФункции // ПолучитьТЧТоварыЧнкаККМ()


Функция  ЗагрузитьТЧТовары(СписокИДЧековВСмене);
	
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	goodsitem.goodsitemid КАК goodsitemid,
	|	goodsitem.cashcode КАК cashcode,
	|	goodsitem.documentid КАК documentid,
	|	goodsitem.deptcode КАК deptcode,
	|	goodsitem.scode КАК scode,
	|	goodsitem.ttime КАК ttime,
	|	goodsitem.opcode КАК opcode,
	|	goodsitem.status КАК status,
	|	goodsitem.bcode КАК bcode,
	|	goodsitem.name КАК name,
	|	goodsitem.articul КАК articul,
	|	goodsitem.measure КАК measure,
	|	goodsitem.bcode_mode КАК bcode_mode,
	|	goodsitem.bcode_main КАК bcode_main,
	|	goodsitem.bquant КАК bquant,
	|	goodsitem.bquant_mode КАК bquant_mode,
	|	goodsitem.ost_modif КАК ost_modif,
	|	goodsitem.cquant КАК cquant,
	|	goodsitem.pricetype КАК pricetype,
	|	goodsitem.pricevcode КАК pricevcode,
	|	goodsitem.price КАК price,
	|	goodsitem.minprice КАК minprice,
	|	goodsitem.pricei КАК pricei,
	|	goodsitem.price_mode КАК price_mode,
	|	goodsitem.tindex КАК tindex,
	|	goodsitem.disc_perc КАК disc_perc,
	|	goodsitem.disc_abs КАК disc_abs,
	|	goodsitem.sumi КАК sumi,
	|	goodsitem.sumb КАК sumb,
	|	goodsitem.sumn КАК sumn,
	|	goodsitem.sume КАК sume,
	|	goodsitem.vatcode1 КАК vatcode1,
	|	goodsitem.vatrate1 КАК vatrate1,
	|	goodsitem.vatsum1 КАК vatsum1,
	|	goodsitem.vatcode2 КАК vatcode2,
	|	goodsitem.vatrate2 КАК vatrate2,
	|	goodsitem.vatsum2 КАК vatsum2,
	|	goodsitem.vatcode3 КАК vatcode3,
	|	goodsitem.vatrate3 КАК vatrate3,
	|	goodsitem.vatsum3 КАК vatsum3,
	|	goodsitem.vatcode4 КАК vatcode4,
	|	goodsitem.vatrate4 КАК vatrate4,
	|	goodsitem.vatsum4 КАК vatsum4,
	|	goodsitem.vatcode5 КАК vatcode5,
	|	goodsitem.vatrate5 КАК vatrate5,
	|	goodsitem.vatsum5 КАК vatsum5,
	|	goodsitem.docnum КАК docnum,
	|	goodsitem.c_link КАК c_link,
	|	goodsitem.code КАК code,
	|	goodsitem.posnum КАК posnum,
	|	goodsitem.frnum КАК frnum,
	|	goodsitem.extendetoptions КАК extendetoptions,
	|	goodsitem.opid КАК opid,
	|	goodsitem.buttonid КАК buttonid,
	|	goodsitem.paymentitemid КАК paymentitemid,
	|	goodsitem.departmentid КАК departmentid,
	|	goodsitem.taramode КАК taramode,
	|	goodsitem.taracapacity КАК taracapacity,
	|	goodsitem.extdocid КАК extdocid,
	|	goodsitem.additionaldata КАК additionaldata,
	|	goodsitem.reverseoperation КАК reverseoperation,
	|	goodsitem.update_time КАК update_time,
	|	goodsitem.aspectschemecode КАК aspectschemecode,
	|	goodsitem.aspectvaluesetcode КАК aspectvaluesetcode,
	|	goodsitem.excisemark КАК excisemark,
	|	goodsitem.inn КАК inn,
	|	goodsitem.kpp КАК kpp,
	|	goodsitem.alcoholpercent КАК alcoholpercent,
	|	goodsitem.tags КАК tags,
	|	goodsitem.consultantid КАК consultantid,
	|	goodsitem.alctypecode КАК alctypecode,
	|	goodsitem.alcocode КАК alcocode,
	|	goodsitem.additionalexcisemark КАК additionalexcisemark,
	|	goodsitem.packingprice КАК packingprice,
	|	goodsitem.additionalbarcode КАК additionalbarcode,
	|	goodsitem.paymentobject КАК paymentobject,
	|	goodsitem.paymentmethod КАК paymentmethod,
	|	goodsitem.minretailprice КАК minretailprice,
	|	goodsitem.customsdeclarationnumber КАК customsdeclarationnumber,
	|	goodsitem.manufacturercountrycode КАК manufacturercountrycode,
	|	goodsitem.pricedoctype КАК pricedoctype,
	|	goodsitem.excisetype КАК excisetype,
	|	goodsitem.prepackaged КАК prepackaged,
	|	goodsitem.ntin КАК ntin
	|ИЗ
	|	ВнешнийИсточникДанных.КассовыйСервер.Таблица.goodsitem КАК goodsitem
	|ГДЕ
	|	goodsitem.documentid В(&documentid)";
	
	Запрос.УстановитьПараметр("documentid", СписокИДЧековВСмене);
	
	РезультатЗапроса = Запрос.Выполнить().Выгрузить();
	
	Возврат РезультатЗапроса;
	
КонецФункции	
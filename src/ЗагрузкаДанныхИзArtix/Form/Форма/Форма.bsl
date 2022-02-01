
&НаСервере
Процедура ЗагрузитьКассовыеСменыНаСервере()
	
	//1. В начале отрабатываем изменения по текущим сменам, который уже есть в 1С
	
	// Получаем список всех не закрытых смен в 1С, в норме все смены кроме текущего и прошлого дня должны
	// быть закрыты
	СписокНеЗакрытыхКассовыхСмен = ПолучитьСписокНеЗакрытыхКассовыхСменВ1С();
	
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
					  ТаблицаШапкиЧеков = ЗагрузитьЧекиНаСервере(текКассоваяСмена.НомерСменыККТ);
				      СоздатьЧеки(ТаблицаШапкиЧеков);
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
	
	Запрос.УстановитьПараметр("cashcode", тНомерСмены.cashcode);
	Запрос.УстановитьПараметр("workshiftid", тНомерСмены.shiftnum);
	
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
Функция СоздатьЧеки(ТаблицаШапкиЧеков);

	

КонецФункции //СоздатьЧеки(ТаблицаШапкиЧеков)
 
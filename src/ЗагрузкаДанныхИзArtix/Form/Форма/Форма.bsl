
&НаСервере
Процедура ЗагрузитьКассовыеСменыНаСервере()
	
	shiftnum = 14;
	
	Запрос = Новый Запрос;
	
	ТекстЗапросаКассовыеСмены = ВернутьТекстЗапросаКассовыеСмены();
	Запрос.Текст = ТекстЗапросаКассовыеСмены;
	Запрос.УстановитьПараметр("shiftnum", shiftnum);

	
	Результат = Запрос.Выполнить().Выгрузить();
	
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
		|	workshift.shiftnum = &shiftnum";
	
	//Запрос.УстановитьПараметр("shiftnum", shiftnum);

	
	Возврат ТекстЗапроса;
	
КонецФункции // ВернутьТекстЗапросаКассовыеСмены()
 


Функция ОткрытьКассовуюСмену(Результат)
	СсылкаНаКассовуюСмену = Документы.КассоваяСмена.ПустаяСсылка();
	
	МассивДокументовКассоваяСмена = Новый Массив; 
	 
	Для каждого тСтрока Из Результат Цикл
		
		Если НЕ ПроверитьНаличиеКассовойСмены(тСтрока.shiftnum, тСтрока.cashcode,тСтрока.shopcode) Тогда
	
		 СсылкаНаКассовуюСмену = Документы.КассоваяСмена.СоздатьДокумент();
		 СсылкаНаКассовуюСмену.Дата = тСтрока.time_beg;
		 СсылкаНаКассовуюСмену.ДатаСменыККТ  = тСтрока.time_beg;
		 СсылкаНаКассовуюСмену.НомерСменыККТ = тСтрока.shiftnum;
		 СсылкаНаКассовуюСмену.НачалоКассовойСмены = тСтрока.time_beg;
		 //СсылкаНаКассовуюСмену.Статус = Перечисления.СтатусыКассовойСмены.Открыта;
		 СсылкаНаКассовуюСмену.Статус = Перечисления.СтатусыКассовойСмены.Закрыта;

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



Функция ПроверитьНаличиеКассовойСмены(НомерСмены,Касса,Магазин)
	
	
	
	Возврат Ложь;
КонецФункции	
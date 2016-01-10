program main;
{$mode objfpc}{$H+}
uses
	crt, 
	keyboard,
	sysutils;
type
	Tdouble4bit = record //хранит 2 4-битовых значения
		first4bit: byte;
		second4bit: byte;
	end;
	Toption = record //позиция курсора в меню или в редакторе
		hor: byte;
		ver: byte;
	end;
	Tquad2bit = record //хранит 4 2-битовых значения
		first2bit: byte;
		second2bit: byte;
		third2bit: byte;
		fourth2bit: byte;
	end;
	Toctbit = record //хранит 4 2-битовых значения
		firstbit: byte;
		secondbit: byte;
		thirdbit: byte;
		fourthbit: byte;
		fifthbit: byte;
		sixthbit: byte;
		seventhbit: byte;
		eightthbit: byte;
	end;
	TSymbol = array [0..63] of byte; //64 bytes //массив точек одного символа шрифта
var
	file1: file; //файл шрифта
	file2: file; //вспомогательная файловая переменная. Для бэкапа файлов
	byte1: byte; //считываемый или записываемый из/в файл байт
	i, j: word; //для циклов
	option: Toption; //позиция курсора в меню или редакторе
	key: TKeyEvent; //последняя нажатая клавиша
	exit: boolean; //подтверждает выход из цикла
	choosefile: string; //выбранный для манипуляции файл шрифта
	chars: array of TSymbol; //массив растров символов шрифта
	
//разбивает байт на старшие и младшие 4 бита
function byteto4bit(num: byte): Tdouble4bit;
begin
	result.first4bit := num div 16;
	result.second4bit := num mod 16;
end;

//разбивает байт на 4 2-хбитных числа
function byteto2bit(num: byte): Tquad2bit;
begin
	result.first2bit := num div 64;
	result.second2bit := num div 16 mod 4;
	result.third2bit := num div 4 mod 4;
	result.fourth2bit := num mod 4;
end;

function bytetobit(num: byte): Toctbit;
begin
	result.firstbit := num div 128;
	result.secondbit := num div 64 mod 2;
	result.thirdbit := num div 32 mod 2;
	result.fourthbit := num div 16 mod 2;
	result.fifthbit := num div 8 mod 2;
	result.sixthbit := num div 4 mod 2;
	result.seventhbit := num div 2 mod 2;
	result.eightthbit := num mod 2;
end;

//подсвечивает нужный пункт меню в зависимости от позиции курсора
procedure menuoption(choose: byte);
begin
	if (option.ver = choose) then
	begin
		textbackground(15);
		textcolor(0);
	end
	else
	begin
		textbackground(0);
		textcolor(15);
	end;
end;

//редактировать CGA-шрифт
procedure editcga(filename: string);
begin
	clrscr();
	option.hor := 0; //устанавливаем курсор меню на 0
	option.ver := 0;
	i := 0;
	j := 0;
	assign(file1, filename);
	reset(file1, 1); //чтение файла шрифта
	SetLength(chars, filesize(file1) div 16); //устанавливаем размер массива в который будет загружаться шрифт
	//переносим данные из файла в массив chars
	for i := 0 to filesize(file1) div 16 - 1 do
		for j := 0 to 15 do
		begin
			blockread(file1, byte1, 1);
			chars[i][j * 4] := byteto2bit(byte1).first2bit;
			chars[i][j * 4 + 1] := byteto2bit(byte1).second2bit;
			chars[i][j * 4 + 2] := byteto2bit(byte1).third2bit;
			chars[i][j * 4 + 3] := byteto2bit(byte1).fourth2bit;
		end;
	//выводим символы в редактор по одному
	for i := 0 to filesize(file1) div 16 - 1 do
		repeat
			textcolor(15);
			clrscr();
			writeln('0000000000');
			for j := 0 to 63 do
			begin
				if (j mod 8 = 0) then
				begin
					textcolor(15);
					write('0');
				end;
				textcolor(chars[i][j]);
				if (option.ver * 8 + option.hor = j) then //отрисовка курсора белым фоном
					textbackground(15);
				write(chr(176));
				textbackground(0);
				if (j mod 8 = 7) then
				begin
					textcolor(15);
					writeln('0');
				end;
			end;
			textcolor(15);
			writeln('0000000000');
			writeln();
			//отрисовка подсказки
			write('Controls: Num 0 - ');
			textcolor(0);
			write(chr(176));
			textcolor(15);
			write(' Num 1 - ');
			textcolor(1);
			write(chr(176));
			textcolor(15);
			write(' Num 2 - ');
			textcolor(2);
			write(chr(176));
			textcolor(15);
			write(' Num 3 - ');
			textcolor(3);
			writeln(chr(176));
			textcolor(15);
			write('Return - next char');
			
			
			//управление
			key := GetKeyEvent;
			if (key div 256 mod 256 = 80) and (option.ver < 7) then //вправо
				option.ver := option.ver + 1;
			if (key div 256 mod 256 = 72) and (option.ver > 0) then //влево
				option.ver := option.ver - 1;
			if (key div 256 mod 256 = 75) and (option.hor > 0) then //вверх
				option.hor := option.hor - 1;
			if (key div 256 mod 256 = 77) and (option.hor < 7) then //вниз
				option.hor := option.hor + 1;
			//закрасить одним из цветов
			if (key div 256 mod 256 = 11) then //Num 0
				chars[i][option.ver * 8 + option.hor] := 0;
			if (key div 256 mod 256 = 2) then //Num 1
				chars[i][option.ver * 8 + option.hor] := 1;
			if (key div 256 mod 256 = 3) then //Num 2
				chars[i][option.ver * 8 + option.hor] := 2;
			if (key div 256 mod 256 = 4) then //Num 3
				chars[i][option.ver * 8 + option.hor] := 3;
			
			
		until key div 256 mod 256 = 28;
	
	
	
	
	close(file1); //закрываем читаемый файл
	rewrite(file1, 1); //открываем его же для записи
	for i := 0 to length(chars)-1 do //записываем
		for j := 0 to 15 do
		begin
			byte1 := chars[i][j * 4] * 64 + chars[i][j * 4 + 1] * 16 + chars[i][j * 4 + 2] * 4 + chars[i][j * 4 + 3];
			blockwrite(file1, byte1, 1);
		end;
	close(file1); //закрываем файл
	option.hor := 0; //устанавливаем курсор в 0
end;

//редактировать EGA-шрифт
procedure editega(filename: string);
begin
	clrscr();
	option.hor := 0; //устанавливаем курсор меню на 0
	option.ver := 0;
	i := 0;
	j := 0;
	assign(file1, filename);
	reset(file1, 1); //чтение файла шрифта
	SetLength(chars, filesize(file1) div 8); //устанавливаем размер массива в который будет загружаться шрифт
	//переносим данные из файла в массив chars
	for i := 0 to filesize(file1) div 8 - 1 do
		for j := 0 to 7 do
		begin
			blockread(file1, byte1, 1);
			chars[i][j * 8] := bytetobit(byte1).firstbit;
			chars[i][j * 8 + 1] := bytetobit(byte1).secondbit;
			chars[i][j * 8 + 2] := bytetobit(byte1).thirdbit;
			chars[i][j * 8 + 3] := bytetobit(byte1).fourthbit;
			chars[i][j * 8 + 4] := bytetobit(byte1).fifthbit;
			chars[i][j * 8 + 5] := bytetobit(byte1).sixthbit;
			chars[i][j * 8 + 6] := bytetobit(byte1).seventhbit;
			chars[i][j * 8 + 7] := bytetobit(byte1).eightthbit;
		end;
	//выводим символы в редактор по одному
	for i := 0 to filesize(file1) div 8 - 1 do
		repeat
			textcolor(15);
			clrscr();
			writeln('0000000000');
			for j := 0 to 63 do
			begin
				if (j mod 8 = 0) then
				begin
					textcolor(15);
					write('0');
				end;
				textcolor(chars[i][j]);
				if (option.ver * 8 + option.hor = j) then //отрисовка курсора белым фоном
					textbackground(15);
				write(chr(176));
				textbackground(0);
				if (j mod 8 = 7) then
				begin
					textcolor(15);
					writeln('0');
				end;
			end;
			textcolor(15);
			writeln('0000000000');
			writeln();
			//отрисовка подсказки
			write('Controls: Num 0 - ');
			textcolor(0);
			write(chr(176));
			textcolor(15);
			write(' Num 1 - ');
			textcolor(1);
			writeln(chr(176));
			textcolor(15);
			write('Return - next char');
						
			
			
			//управление
			key := GetKeyEvent;
			if (key div 256 mod 256 = 80) and (option.ver < 7) then //вправо
				option.ver := option.ver + 1;
			if (key div 256 mod 256 = 72) and (option.ver > 0) then //влево
				option.ver := option.ver - 1;
			if (key div 256 mod 256 = 75) and (option.hor > 0) then //вверх
				option.hor := option.hor - 1;
			if (key div 256 mod 256 = 77) and (option.hor < 7) then //вниз
				option.hor := option.hor + 1;
			//закрасить одним из цветов
			if (key div 256 mod 256 = 11) then //Num 0
				chars[i][option.ver * 8 + option.hor] := 0;
			if (key div 256 mod 256 = 2) then //Num 1
				chars[i][option.ver * 8 + option.hor] := 1;
			
			
		until key div 256 mod 256 = 28;
	
	
	
	
	close(file1); //закрываем читаемый файл
	rewrite(file1, 1); //открываем его же для записи
	for i := 0 to length(chars)-1 do //записываем
		for j := 0 to 7 do
		begin
			byte1 := chars[i][j * 8] * 128 + chars[i][j * 8 + 1] * 64 + chars[i][j * 8 + 2] * 32 + chars[i][j * 8 + 3] * 16
			+ chars[i][j * 8 + 4] * 8 + chars[i][j * 8 + 5] * 4 + chars[i][j * 8 + 6] * 2 + chars[i][j * 8 + 7];
			blockwrite(file1, byte1, 1);
		end;
	close(file1); //закрываем файл
	option.hor := 0; //устанавливаем курсор в 0
end;

//редактировать T16-шрифт
procedure editt16(filename: string);
begin
	clrscr();
	option.hor := 0; //устанавливаем курсор меню на 0
	option.ver := 0;
	i := 0;
	j := 0;
	
	assign(file1, filename);
	reset(file1, 1); //чтение файла шрифта
	
	SetLength(chars, filesize(file1) div 32); //устанавливаем размер массива в который будет загружаться шрифт
	
	//переносим данные из файла в массив chars
	for i := 0 to filesize(file1) div 32 - 1 do
		for j := 0 to 31 do
		begin
			blockread(file1, byte1, 1);
			chars[i][j * 2] := byteto4bit(byte1).first4bit;
			chars[i][j * 2 + 1] := byteto4bit(byte1).second4bit;
		end;
	//выводим символы в редактор по одному
	for i := 0 to filesize(file1) div 32 - 1 do
		repeat
			textcolor(15);
			clrscr();
			writeln('0000000000');
			for j := 0 to 63 do
			begin
				if (j mod 8 = 0) then
				begin
					textcolor(15);
					write('0');
				end;
				textcolor(chars[i][j]);
				if (option.ver * 8 + option.hor = j) then //отрисовка курсора белым фоном
					textbackground(15);
				write(chr(176));
				textbackground(0);
				if (j mod 8 = 7) then
				begin
					textcolor(15);
					writeln('0');
				end;
			end;
			textcolor(15);
			writeln('0000000000');
			writeln();
			//отрисовка подсказки
			write('Controls: Num 0 - ');
			textcolor(0);
			write(chr(176));
			textcolor(15);
			write(' Num 1 - ');
			textcolor(1);
			write(chr(176));
			textcolor(15);
			write(' Num 2 - ');
			textcolor(2);
			write(chr(176));
			textcolor(15);
			write(' Num 3 - ');
			textcolor(3);
			write(chr(176));
			textcolor(15);
			write(' Num 4 - ');
			textcolor(4);
			write(chr(176));
			textcolor(15);
			write(' Num 5 - ');
			textcolor(5);
			write(chr(176));
			textcolor(15);
			write(' Num 6 - ');
			textcolor(6);
			write(chr(176));
			textcolor(15);
			write(' Num 7 - ');
			textcolor(7);
			write(chr(176));
			textcolor(15);
			write(' Num 8 - ');
			textcolor(8);
			write(chr(176));
			textcolor(15);
			write(' Num 9 - ');
			textcolor(9);
			write(chr(176));
			textcolor(15);
			write(' A - ');
			textcolor(10);
			write(chr(176));
			textcolor(15);
			write(' B - ');
			textcolor(11);
			write(chr(176));
			textcolor(15);
			write(' C - ');
			textcolor(12);
			write(chr(176));
			textcolor(15);
			write(' D - ');
			textcolor(13);
			write(chr(176));
			textcolor(15);
			write(' E - ');
			textcolor(14);
			write(chr(176));
			textcolor(15);
			write(' F - ');
			textcolor(15);
			writeln(chr(176));
			textcolor(15);
			write('Return - next char');
			
			
			//управление
			key := GetKeyEvent;
			if (key div 256 mod 256 = 80) and (option.ver < 7) then //вправо
				option.ver := option.ver + 1;
			if (key div 256 mod 256 = 72) and (option.ver > 0) then //влево
				option.ver := option.ver - 1;
			if (key div 256 mod 256 = 75) and (option.hor > 0) then //вверх
				option.hor := option.hor - 1;
			if (key div 256 mod 256 = 77) and (option.hor < 7) then //вниз
				option.hor := option.hor + 1;
			//закрасить одним из цветов
			if (key div 256 mod 256 = 11) then //Num 0
				chars[i][option.ver * 8 + option.hor] := 0;
			if (key div 256 mod 256 = 2) then //Num 1
				chars[i][option.ver * 8 + option.hor] := 1;
			if (key div 256 mod 256 = 3) then //Num 2
				chars[i][option.ver * 8 + option.hor] := 2;
			if (key div 256 mod 256 = 4) then //Num 3
				chars[i][option.ver * 8 + option.hor] := 3;
			if (key div 256 mod 256 = 5) then //Num 4
				chars[i][option.ver * 8 + option.hor] := 4;
			if (key div 256 mod 256 = 6) then //Num 5
				chars[i][option.ver * 8 + option.hor] := 5;
			if (key div 256 mod 256 = 7) then //Num 6
				chars[i][option.ver * 8 + option.hor] := 6;
			if (key div 256 mod 256 = 8) then //Num 7
				chars[i][option.ver * 8 + option.hor] := 7;
			if (key div 256 mod 256 = 9) then //Num 8
				chars[i][option.ver * 8 + option.hor] := 8;
			if (key div 256 mod 256 = 10) then //Num 9
				chars[i][option.ver * 8 + option.hor] := 9;
			if (key div 256 mod 256 = 30) then //A
				chars[i][option.ver * 8 + option.hor] := 10;
			if (key div 256 mod 256 = 48) then //B
				chars[i][option.ver * 8 + option.hor] := 11;
			if (key div 256 mod 256 = 46) then //C
				chars[i][option.ver * 8 + option.hor] := 12;
			if (key div 256 mod 256 = 32) then //D
				chars[i][option.ver * 8 + option.hor] := 13;
			if (key div 256 mod 256 = 18) then //E
				chars[i][option.ver * 8 + option.hor] := 14;
			if (key div 256 mod 256 = 33) then //F
				chars[i][option.ver * 8 + option.hor] := 15;
			
		until key div 256 mod 256 = 28;
	
	
	
	close(file1); //закрываем читаемый файл
	rewrite(file1, 1); //открываем его же для записи
	for i := 0 to length(chars)-1 do //записываем
		for j := 0 to 31 do
		begin
			byte1 := chars[i][j * 2] * 16 + chars[i][j * 2 + 1];
			blockwrite(file1, byte1, 1);
		end;
	close(file1); //закрываем файл
	option.hor := 0; //устанавливаем курсор в 0
end;

begin
	clrscr();
	InitKeyBoard; //инициализация клавиатурного модуля
	exit := false; //запретить выход из цикла
	option.hor := 0; //курсор меню в 0
	option.ver := 0;
	repeat //Рисуем главное меню
		textbackground(0);
		textcolor(15);
		clrscr();
		writeln ('Wizardry VI Font Editor.');
		writeln ('Made by Omikron');
		writeln ();
		writeln ('Choose font file for editing or exit:');
		menuoption(0);
		writeln ('Wfont0.cga');
		menuoption(1);
		writeln ('Wfont0.ega');
		menuoption(2);
		writeln ('Wfont0.t16');
		menuoption(3);
		writeln ('Wfont1.cga');
		menuoption(4);
		writeln ('Wfont1.ega');
		menuoption(5);
		writeln ('Wfont1.t16');
		menuoption(6);
		writeln ('Wfont2.cga');
		menuoption(7);
		writeln ('Wfont2.ega');
		menuoption(8);
		writeln ('Wfont2.t16');
		menuoption(9);
		writeln ('Wfont3.cga');
		menuoption(10);
		writeln ('Wfont3.ega');
		menuoption(11);
		writeln ('Wfont3.t16');
		menuoption(12);
		writeln ('Wfont4.cga');
		menuoption(13);
		writeln ('Wfont4.ega');
		menuoption(14);
		writeln ('Wfont4.t16');
		menuoption(15);
		writeln ('Exit');
		key:=GetKeyEvent; //считываем клавишу
		//key:=TranslateKeyEvent(key);
		//writeln(key div 256 mod 256);
		//delay(1000);
		if (key div 256 mod 256 = 80) and (option.ver < 15) then //вниз
			option.ver := option.ver + 1;
		if (key div 256 mod 256 = 72) and (option.ver > 0) then //вверх
			option.ver := option.ver - 1;
		if (key div 256 mod 256 = 28) then //Ввод
		begin
			case option.ver of //выбираем файл в зависимости от выбранного пункта меню
				0:
					choosefile := 'Wfont0.cga';
				1:
					choosefile := 'Wfont0.ega';
				2:
					choosefile := 'Wfont0.t16';
				3:
					choosefile := 'Wfont1.cga';
				4:
					choosefile := 'Wfont1.ega';
				5:
					choosefile := 'Wfont1.t16';
				6:
					choosefile := 'Wfont2.cga';
				7:
					choosefile := 'Wfont2.ega';
				8:
					choosefile := 'Wfont2.t16';
				9:
					choosefile := 'Wfont3.cga';
				10:
					choosefile := 'Wfont3.ega';
				11:
					choosefile := 'Wfont3.t16';
				12:
					choosefile := 'Wfont4.cga';
				13:
					choosefile := 'Wfont4.ega';
				14:
					choosefile := 'Wfont4.t16';
				15: //выход из программы
				begin
					DoneKeyBoard;
					halt();
				end;
			end;
			option.ver := 0;
			repeat //подменю для манипуляции с файлом шрифта
				textbackground(0);
				textcolor(15);
				clrscr();
				writeln ('Choose file action:');
				menuoption(0);
				writeln ('Create backup '+ choosefile);
				menuoption(1);
				writeln ('Edit '+ choosefile);
				menuoption(2);
				writeln ('Backup '+ choosefile);
				menuoption(3);
				writeln ('Back to main menu');
				key:=GetKeyEvent;
				if (key div 256 mod 256 = 80) and (option.ver < 3) then //нвиз
					option.ver := option.ver + 1;
				if (key div 256 mod 256 = 72) and (option.ver > 0) then //вверх
					option.ver := option.ver - 1;
				if (key div 256 mod 256 = 28) then //Ввод
					case option.ver of
						0: //Создать бэкап
						begin
							Assign(file1, choosefile);
							Assign(file2, choosefile + '.bak');
							Reset(file1, 1);
							Rewrite(file2, 1);
							repeat
								blockread(file1, byte1, 1);
								blockwrite(file2, byte1, 1);
							until EOF(file1);
							close(file1);
							close(file2); 
							writeln();
							write('Backup file for '+choosefile+' created.');
							delay(2000);
						end;
						1: //Открыть шрифт в редакторе
						begin
							case choosefile[8] of
								'c':
									if (FileExists (choosefile)) then
										editcga(choosefile)
									else
									begin
										writeln();
										write('File '+choosefile+' not found.');
										delay(2000);
									end;
								'e':
									if (FileExists (choosefile)) then
										editega(choosefile)
									else
									begin
										writeln();
										write('File '+choosefile+' not found.');
										delay(2000);
									end;
								't':
									if (FileExists (choosefile)) then
										editt16(choosefile)
									else
									begin
										writeln();
										write('File '+choosefile+' not found.');
										delay(2000);
									end;
							end;		
						end;
						2: //Бэкапнуть файл
						begin
							if (FileExists (choosefile + '.bak')) then
							begin
								Assign(file1, choosefile);
								Assign(file2, choosefile + '.bak');
								Reset(file2, 1);
								Rewrite(file1, 1);
								repeat
									blockread(file2, byte1, 1);
									blockwrite(file1, byte1, 1);
								until EOF(file2);
								close(file1);
								close(file2); 
								writeln();
								write('File '+choosefile+' backuped.');
								delay(2000);
							end
							else
							begin
								writeln();
								write('File '+choosefile+'.bak not found.');
								delay(2000);
							end;
						end;
						3://выход в главное меню
						begin
							exit := true;
							option.ver := 0;
						end;
					end
			until (exit);
			exit := false;
		end;
	until (exit);
	
	
	
	
	readln();
end.

unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, SyncObjs;

type
  TForm1 = class(TForm)
    CreateBTN: TButton;
    JobBTN: TButton;
    Label1: TLabel;
    Memo1: TMemo;
    Panel1: TPanel;
    Splitter1: TSplitter;
    Panel2: TPanel;
    Panel3: TPanel;
    Splitter2: TSplitter;
    Memo2: TMemo;
    Label2: TLabel;
    Label3: TLabel;
    Edit1: TEdit;
    Label4: TLabel;
    Edit2: TEdit;
    Button1: TButton;
    procedure CreateBTNClick(Sender: TObject);
    procedure JobBTNClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
// Глобальные переменные
var
  n1, n2, j, i10, i20 : integer;
  p1, p2: ^integer;
  mas: array of integer;   // Динамический массив
  hThread1, hThread2: integer;
  ThreadID1, ThreadID2: cardinal;
  C_S: TCriticalSection;   // Критическая секция

function ThreadFunc(lp: PInteger): integer; stdcall;
var
  i: integer;
  n: integer;
begin
// Вход в критическую секцию
// Код, выполнение которого параллельно запрещено
  while j < n2 do
    begin
      C_S.Enter;

      for i := 1 to n1 do
        begin
          n := Length(mas);
          if lp^ = 1 then
            Form1.Memo1.Lines.Add('mas[' + IntToStr(i+j*n1) + ']= ' + IntToStr(mas[n-1]))
          else
            Form1.Memo2.Lines.Add('mas[' + IntToStr(i+j*n1) + ']= ' + IntToStr(mas[n-1]));
          Setlength(mas,n+1);
          mas[n] := mas[n-1]+1;
        end; {for}

      Inc(j);
      Sleep(5);    // Время задержки перед выходом из критической секции
// Выход из критической секции
      C_S.Leave;
      Sleep(100);  // Время задержки для того, чтобы переключать нити
                   // Подбирается экспериментально, порядка 0,1 секунды
    end; {While}
  Result:= 1;
end;

procedure TForm1.CreateBTNClick(Sender: TObject);// Первая кнопка
begin
  if (Edit1.Text ='') or (Edit2.Text = '') then
    begin
      ShowMessage('Не заданы длина порции чисел' + chr(13) + chr(10) +
                  'или их количество');
      Exit;
    end;
// Установка длины массива
//  SetLength(a, n1*n2);
   n1:= StrToInt(Edit1.Text);
   n2:= StrToInt(Edit2.Text);

// Создание первой нити
  i10:= 1;
  p1:= @i10;
  hThread1:= CreateThread(nil, // Указатель на атрибуты безопасности(по умолчанию)
               0,          // Размер стека, 0 - размер по умолчанию - 1 мегабайт
               @ThreadFunc,       // Указатель на процедуру нити
               p1,                // Указатель на аргумент этой процедуры
               CREATE_SUSPENDED,  // Нить не стартует сразу, 0 - стартует сразу
               ThreadID1);        //  Идентификатор нити, выходной параметр
  if hThread1 =0 then
    begin
      ShowMessage('Не создана первая нить');
      Exit;
    end;

// Создание второй нити
  i20:= 2;
  p2:= @i20;
  hThread2:= CreateThread(nil, // Указатель на атрибуты безопасности(по умолчанию)
               0,          // Размер стека, 0 - размер по умолчанию - 1 мегабайт
               @ThreadFunc,       // Указатель на процедуру нити
               p2,                // Указатель на аргумент этой процедуры
               CREATE_SUSPENDED,  // Нить не стартует сразу, 0 - стартует сразу
               ThreadID2);        // Идентификатор нити, выходной параметр
//  ShowMessage('p2^=' + IntToStr(p2^));

  if hThread2 =0 then
    begin
      ShowMessage('Не создана вторая нить');
      Exit;
    end;

  CreateBTN.Enabled:= false;
  JobBTN.Enabled:= true;
end;

procedure TForm1.JobBTNClick(Sender: TObject); // Вторая кнопка
var
  Threads: array[0..1] of integer;
begin
// Запускаем нити
  ResumeThread(hThread1);
  ResumeThread(hThread2);

  SetLength(mas, 1);
  j:= 0;
  JobBTN.Enabled:= false;

{  Threads[0]:= hThread1;
  Threads[1]:= hThread2;
  WaitForMultipleObjects(2, @Threads, true,INFINITE);
  CloseHandle(hThread1);
  CloseHandle(hThread2);
  CreateBTN.Enabled:= true; }
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  SetLength(mas, 1);
  mas[0]:= 1;
// Создаем критическую секцию
  C_S:= TCriticalSection.Create;
end;   {FormCreate}

procedure TForm1.FormDestroy(Sender: TObject);
begin
// Удаляем критическую секцию
  C_S.Free;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Memo1.Clear;
  Memo2.Clear;
  Edit1.Clear;
  Edit2.Clear;
end;

end.

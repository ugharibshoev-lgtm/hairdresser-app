from pathlib import Path
from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.section import WD_SECTION
from docx.shared import Cm, Pt
from docx.oxml.ns import qn

ROOT = Path(__file__).parent
OUT = ROOT / "Курсовая_работа_Парикмахерская_черновик.docx"
SCREEN_CLIENTS = Path(r"C:\Users\user\AppData\Local\Temp\codex-clipboard-66ae001b-f0aa-45a3-b3c2-a989bbbbc40e.png")
SCREEN_REPORT = Path(r"C:\Users\user\AppData\Local\Temp\codex-clipboard-34fce9da-bf9f-4ac2-a3d2-e2f253560960.png")

doc = Document()
section = doc.sections[0]
section.top_margin = Cm(2)
section.bottom_margin = Cm(2)
section.left_margin = Cm(3)
section.right_margin = Cm(1.5)

style = doc.styles["Normal"]
style.font.name = "Times New Roman"
style._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
style._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
style.font.size = Pt(14)
style.paragraph_format.first_line_indent = Cm(1.25)
style.paragraph_format.line_spacing = 1.5

for name in ("Title", "Heading 1", "Heading 2"):
    s = doc.styles[name]
    s.font.name = "Times New Roman"
    s._element.rPr.rFonts.set(qn("w:ascii"), "Times New Roman")
    s._element.rPr.rFonts.set(qn("w:hAnsi"), "Times New Roman")
    s.font.color.rgb = None

def p(text="", bold=False, center=False):
    paragraph = doc.add_paragraph()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER if center else WD_ALIGN_PARAGRAPH.JUSTIFY
    run = paragraph.add_run(text)
    run.bold = bold
    return paragraph

def heading(text, level=1):
    h = doc.add_heading(text, level=level)
    h.alignment = WD_ALIGN_PARAGRAPH.CENTER if level == 1 else WD_ALIGN_PARAGRAPH.LEFT
    return h

def figure(path, caption):
    if path.exists():
        para = doc.add_paragraph()
        para.alignment = WD_ALIGN_PARAGRAPH.CENTER
        para.add_run().add_picture(str(path), width=Cm(15.5))
        c = doc.add_paragraph(caption)
        c.alignment = WD_ALIGN_PARAGRAPH.CENTER
        c.runs[0].italic = True

# Cover page
p("БЕЛОРУССКИЙ НАЦИОНАЛЬНЫЙ ТЕХНИЧЕСКИЙ УНИВЕРСИТЕТ", center=True)
p("Факультет информационных технологий и робототехники", center=True)
doc.add_paragraph("\n\n")
p("КУРСОВАЯ РАБОТА", bold=True, center=True)
p("по дисциплине «Конструирование программных средств»", center=True)
doc.add_paragraph("\n")
p("Разработка информационной системы для автоматизации работы парикмахерской", bold=True, center=True)
doc.add_paragraph("\n\n\n")
right = doc.add_paragraph()
right.alignment = WD_ALIGN_PARAGRAPH.RIGHT
right.add_run("Выполнил: Увайдо Гарибшоев\nГруппа: 10201324\nКурс: 3\nРуководитель: Станкевич С.Н.")
doc.add_paragraph("\n\n")
p("Минск 2026", center=True)
doc.add_page_break()

heading("СОДЕРЖАНИЕ")
for item in [
    "Введение", "1 Анализ предметной области", "2 Проектирование базы данных",
    "3 Реализация приложения", "4 Тестирование", "Заключение", "Приложение А Скриншоты программы",
]:
    p(item)
doc.add_page_break()

heading("ВВЕДЕНИЕ")
p("Парикмахерская ежедневно обслуживает клиентов, распределяет записи между мастерами и оказывает услуги различной стоимости и длительности. При ведении данных вручную повышается риск потери сведений о клиенте, ошибки в расписании и затрудняется подсчёт выручки.")
p("Целью курсовой работы является разработка информационной системы для автоматизации работы парикмахерской. Система предназначена для хранения сведений о клиентах, мастерах, услугах и записях на обслуживание, а также для получения отчёта по работе мастеров.")
p("Для достижения цели были поставлены задачи: проанализировать предметную область; спроектировать реляционную базу данных; реализовать настольное приложение на Python; организовать работу с Microsoft SQL Server; выполнить тестирование основных функций программы.")

heading("1 АНАЛИЗ ПРЕДМЕТНОЙ ОБЛАСТИ")
p("Предметной областью является деятельность парикмахерской. Основными объектами являются клиент, мастер, услуга и запись. Клиент может записываться на разные услуги, мастер оказывает услуги клиентам, а каждая запись фиксирует дату, время, клиента, мастера и выбранную услугу.")
heading("1.1 Функциональные требования", 2)
for text in [
    "просмотр списка клиентов, мастеров, услуг и записей;",
    "добавление клиентов, мастеров, услуг и записей;",
    "удаление выбранной записи при отсутствии ограничений целостности;",
    "обновление данных после выполнения операции;",
    "формирование отчёта по количеству записей и выручке каждого мастера.",
]:
    doc.add_paragraph(text, style="List Bullet")
heading("1.2 Нефункциональные требования", 2)
p("Программа должна иметь понятный графический интерфейс на русском языке, работать с Microsoft SQL Server Express и обеспечивать сохранность данных за счёт первичных и внешних ключей базы данных.")

heading("2 ПРОЕКТИРОВАНИЕ БАЗЫ ДАННЫХ")
p("Для хранения данных разработана база HairdresserDB. В ней используются четыре основные таблицы: Clients, Employees, Services и Schedule. Первичные ключи однозначно идентифицируют записи. В таблице Schedule размещены внешние ключи, связывающие запись с клиентом, услугой и мастером.")
heading("2.1 Состав таблиц", 2)
table = doc.add_table(rows=1, cols=3)
table.style = "Table Grid"
for cell, value in zip(table.rows[0].cells, ["Таблица", "Назначение", "Основной ключ"]):
    cell.text = value
for row in [
    ("Clients", "Хранение данных клиентов", "ClientId"),
    ("Employees", "Хранение данных мастеров", "EmployeeId"),
    ("Services", "Перечень услуг, цены и длительности", "ServiceId"),
    ("Schedule", "Расписание и оказанные услуги", "ScheduleId"),
]:
    cells = table.add_row().cells
    for cell, value in zip(cells, row): cell.text = value
p("Связи имеют тип «один ко многим»: один клиент, мастер или услуга могут участвовать во множестве записей расписания.")

heading("3 РЕАЛИЗАЦИЯ ПРИЛОЖЕНИЯ")
p("Настольное приложение реализовано на языке Python с использованием библиотеки Tkinter. Для взаимодействия с Microsoft SQL Server применяется библиотека pyodbc. Строка подключения использует экземпляр SQL Server Express и базу HairdresserDB.")
p("Главное окно содержит разделы «Клиенты», «Мастера», «Услуги», «Записи» и «Отчёты». Каждая таблица отображается в виде списка. Пользователь может добавить новую запись, удалить выбранную запись или обновить данные.")
heading("3.1 Отчёт по мастерам", 2)
p("Отчёт формируется SQL-запросом с группировкой по мастеру. Для каждого мастера рассчитывается количество записей и суммарная стоимость оказанных услуг. Это позволяет оценивать загруженность сотрудников и выручку.")

heading("4 ТЕСТИРОВАНИЕ")
p("Тестирование выполнялось путём запуска приложения и проверки отображения информации из базы данных. Были проверены переходы между разделами, вывод услуг и расписания, а также формирование отчёта по мастерам.")
table = doc.add_table(rows=1, cols=3)
table.style = "Table Grid"
for cell, value in zip(table.rows[0].cells, ["Проверка", "Ожидаемый результат", "Результат"]): cell.text = value
for row in [
    ("Открытие раздела «Клиенты»", "Отображается список клиентов", "Выполнено"),
    ("Открытие раздела «Услуги»", "Отображаются названия, цены и длительность", "Выполнено"),
    ("Открытие раздела «Записи»", "Отображается расписание с клиентом и мастером", "Выполнено"),
    ("Открытие раздела «Отчёты»", "Рассчитывается число записей и выручка", "Выполнено"),
]:
    cells = table.add_row().cells
    for cell, value in zip(cells, row): cell.text = value

heading("ЗАКЛЮЧЕНИЕ")
p("В ходе выполнения курсовой работы была разработана информационная система для автоматизации работы парикмахерской. Создана база данных HairdresserDB, содержащая сведения о клиентах, мастерах, услугах и расписании. Разработано приложение на Python, предоставляющее просмотр и добавление основных данных, а также отчёт о работе мастеров.")
p("Поставленная цель достигнута. Разработанная система может быть расширена функциями редактирования записей, поиска клиентов, авторизации пользователей и дополнительными отчётами.")

heading("ПРИЛОЖЕНИЕ А СКРИНШОТЫ ПРОГРАММЫ")
figure(SCREEN_CLIENTS, "Рисунок А.1 — Окно работы с клиентами")
figure(SCREEN_REPORT, "Рисунок А.2 — Отчёт по мастерам")

doc.save(OUT)
print(OUT)

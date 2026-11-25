"""Desktop application for the HairdresserDB coursework project."""

import tkinter as tk
from tkinter import messagebox, simpledialog, ttk

try:
    import pyodbc
except ImportError:  # Friendly message is shown on startup.
    pyodbc = None


CONNECTION = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost\\SQLEXPRESS;DATABASE=HairdresserDB;Trusted_Connection=yes;"
)


class HairdresserApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Парикмахерская — автоматизация работы")
        self.geometry("1050x620")
        self.minsize(850, 500)
        self.conn = None
        self.current = "clients"
        self.configure(padx=14, pady=14)

        self._connect()
        self._build_ui()
        if self.conn:
            self.load_data()

    def _connect(self):
        if pyodbc is None:
            messagebox.showerror(
                "Нет компонента", "Не установлен pyodbc. Выполните: pip install pyodbc"
            )
            return
        try:
            self.conn = pyodbc.connect(CONNECTION)
        except pyodbc.Error as error:
            messagebox.showerror(
                "Не удалось подключиться",
                "Проверьте, что SQL Server запущен и база HairdresserDB создана.\n\n" + str(error),
            )

    def _build_ui(self):
        header = ttk.Label(self, text="Информационная система парикмахерской", font=("Segoe UI", 18, "bold"))
        header.pack(anchor="w", pady=(0, 10))

        nav = ttk.Frame(self)
        nav.pack(fill="x", pady=(0, 10))
        for title, section in [
            ("Клиенты", "clients"), ("Мастера", "employees"),
            ("Услуги", "services"), ("Записи", "schedule"),
            ("Отчёты", "reports"),
        ]:
            ttk.Button(nav, text=title, command=lambda value=section: self.change_section(value)).pack(side="left", padx=(0, 8))

        self.caption = ttk.Label(self, font=("Segoe UI", 12, "bold"))
        self.caption.pack(anchor="w", pady=(0, 6))

        self.tree = ttk.Treeview(self, show="headings")
        self.tree.pack(fill="both", expand=True)
        scrollbar = ttk.Scrollbar(self, orient="vertical", command=self.tree.yview)
        scrollbar.place(relx=1, rely=0.19, relheight=0.66, anchor="ne")
        self.tree.configure(yscrollcommand=scrollbar.set)

        actions = ttk.Frame(self)
        actions.pack(fill="x", pady=(10, 0))
        self.add_button = ttk.Button(actions, text="Добавить", command=self.add_record)
        self.add_button.pack(side="left", padx=(0, 8))
        self.delete_button = ttk.Button(actions, text="Удалить выбранное", command=self.delete_record)
        self.delete_button.pack(side="left", padx=(0, 8))
        ttk.Button(actions, text="Обновить", command=self.load_data).pack(side="left")

        self.status = ttk.Label(self, text="", foreground="#236b34")
        self.status.pack(anchor="w", pady=(8, 0))

    def change_section(self, section):
        self.current = section
        self.load_data()

    def query(self, sql, parameters=()):
        cursor = self.conn.cursor()
        cursor.execute(sql, parameters)
        return cursor

    def show_rows(self, title, cursor):
        rows = cursor.fetchall()
        columns = [column[0] for column in cursor.description]
        self.caption.configure(text=title)
        self.tree.delete(*self.tree.get_children())
        self.tree["columns"] = columns
        for column in columns:
            self.tree.heading(column, text=column)
            self.tree.column(column, width=max(110, len(column) * 11), anchor="w")
        for row in rows:
            self.tree.insert("", "end", values=["" if item is None else item for item in row])
        self.status.configure(text=f"Показано записей: {len(rows)}")

    def load_data(self):
        if not self.conn:
            return
        statements = {
            "clients": ("Клиенты", "SELECT ClientId, LastName, FirstName, MiddleName, Phone, Address FROM dbo.Clients ORDER BY LastName"),
            "employees": ("Мастера", "SELECT EmployeeId, LastName, FirstName, MiddleName FROM dbo.Employees ORDER BY LastName"),
            "services": ("Услуги", "SELECT ServiceId, ServiceName, Price, DurationMinutes FROM dbo.Services ORDER BY ServiceName"),
            "schedule": ("Записи", """SELECT s.ScheduleId, s.ServiceDate, s.ServiceTime,
                c.LastName + ' ' + c.FirstName AS Client, e.LastName + ' ' + e.FirstName AS Employee,
                srv.ServiceName, srv.Price FROM dbo.Schedule s
                JOIN dbo.Clients c ON c.ClientId=s.ClientId JOIN dbo.Employees e ON e.EmployeeId=s.EmployeeId
                JOIN dbo.Services srv ON srv.ServiceId=s.ServiceId ORDER BY s.ServiceDate, s.ServiceTime"""),
            "reports": ("Отчёт по мастерам", """SELECT e.LastName + ' ' + e.FirstName AS Employee,
                COUNT(s.ScheduleId) AS AppointmentCount, CAST(ISNULL(SUM(srv.Price),0) AS DECIMAL(10,2)) AS Revenue
                FROM dbo.Employees e LEFT JOIN dbo.Schedule s ON s.EmployeeId=e.EmployeeId
                LEFT JOIN dbo.Services srv ON srv.ServiceId=s.ServiceId
                GROUP BY e.LastName, e.FirstName ORDER BY Revenue DESC"""),
        }
        title, sql = statements[self.current]
        try:
            self.show_rows(title, self.query(sql))
            is_report = self.current == "reports"
            self.add_button.configure(state="disabled" if is_report else "normal")
            self.delete_button.configure(state="disabled" if is_report else "normal")
        except pyodbc.Error as error:
            messagebox.showerror("Ошибка запроса", str(error))

    def ask(self, title, fields):
        values = []
        for label, initial in fields:
            value = simpledialog.askstring(title, label, initialvalue=initial, parent=self)
            if value is None:
                return None
            values.append(value.strip())
        return values

    def add_record(self):
        if self.current == "clients":
            values = self.ask("Новый клиент", [("Фамилия", ""), ("Имя", ""), ("Отчество", ""), ("Телефон", ""), ("Адрес", "")])
            sql = "INSERT INTO dbo.Clients (LastName, FirstName, MiddleName, Phone, Address) VALUES (?, ?, ?, ?, ?)"
        elif self.current == "employees":
            values = self.ask("Новый мастер", [("Фамилия", ""), ("Имя", ""), ("Отчество", "")])
            sql = "INSERT INTO dbo.Employees (LastName, FirstName, MiddleName) VALUES (?, ?, ?)"
        elif self.current == "services":
            values = self.ask("Новая услуга", [("Название", ""), ("Цена", "0"), ("Длительность в минутах", "60")])
            if values:
                try:
                    values[1] = float(values[1].replace(",", "."))
                    values[2] = int(values[2])
                except ValueError:
                    messagebox.showwarning("Проверьте данные", "Цена и длительность должны быть числами.")
                    return
            sql = "INSERT INTO dbo.Services (ServiceName, Price, DurationMinutes) VALUES (?, ?, ?)"
        else:
            values = self.ask("Новая запись", [("Дата (ГГГГ-ММ-ДД)", ""), ("Время (ЧЧ:ММ)", ""), ("Код клиента", ""), ("Код услуги", ""), ("Код мастера", "")])
            if values:
                try:
                    values[2:] = [int(item) for item in values[2:]]
                except ValueError:
                    messagebox.showwarning("Проверьте данные", "Коды должны быть целыми числами.")
                    return
            sql = "INSERT INTO dbo.Schedule (ServiceDate, ServiceTime, ClientId, ServiceId, EmployeeId) VALUES (?, ?, ?, ?, ?)"
        if values is None:
            return
        try:
            self.query(sql, values)
            self.conn.commit()
            self.load_data()
        except pyodbc.Error as error:
            messagebox.showerror("Не удалось добавить запись", str(error))

    def delete_record(self):
        selected = self.tree.selection()
        if not selected:
            messagebox.showwarning("Нет выбора", "Сначала выберите строку в таблице.")
            return
        record_id = self.tree.item(selected[0])["values"][0]
        table = {"clients": "Clients", "employees": "Employees", "services": "Services", "schedule": "Schedule"}[self.current]
        key = {"clients": "ClientId", "employees": "EmployeeId", "services": "ServiceId", "schedule": "ScheduleId"}[self.current]
        if not messagebox.askyesno("Подтверждение", "Удалить выбранную запись?"):
            return
        try:
            self.query(f"DELETE FROM dbo.{table} WHERE {key}=?", (record_id,))
            self.conn.commit()
            self.load_data()
        except pyodbc.Error as error:
            messagebox.showerror("Не удалось удалить", "Запись может использоваться в расписании.\n\n" + str(error))


if __name__ == "__main__":
    HairdresserApp().mainloop()

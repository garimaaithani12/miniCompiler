import tkinter as tk
from tkinter import filedialog
from tkinter.scrolledtext import ScrolledText
from PIL import Image, ImageTk, UnidentifiedImageError
from PIL.Image import Resampling
import subprocess
import os
import time
import ttkbootstrap as ttk
from ttkbootstrap.constants import *

class MiniCCompilerApp:                    #main class of appl.
    def __init__(self, root):              #init is constr. that initialises the GUI compo
        self.root = root
        self.root.title("🧠 Mini C Compiler GUI")
        self.root.geometry("900x680")
        self.ast_img = None

        self.setup_tabs()
        self.setup_controls()

    def setup_tabs(self):             #sets up the tab in GUI 
        self.tabs = ttk.Notebook(self.root)
        self.tabs.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Code Input Tab                        
        self.code_frame = ttk.Frame(self.tabs)
        self.code_input = ScrolledText(self.code_frame, font=("Consolas", 12), wrap=tk.WORD)
        self.code_input.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        self.tabs.add(self.code_frame, text="📝 Code Input")

        # Output Tab
        self.output_frame = ttk.Frame(self.tabs)
        self.output_area = ScrolledText(self.output_frame, font=("Courier New", 11), bg="#1c1c1c", fg="#ffffff", insertbackground='white')
        self.output_area.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        self.tabs.add(self.output_frame, text="📤 Output Log")

        # AST Tab
        self.ast_frame = ttk.Frame(self.tabs)
        self.ast_label = ttk.Label(self.ast_frame, text="🌳 AST image will appear here", anchor="center")
        self.ast_label.pack(expand=True, padx=20, pady=20)
        self.tabs.add(self.ast_frame, text="🌳 AST")

    def setup_controls(self):     #set up of button in GUI like open , compile, exit
        btn_frame = ttk.Frame(self.root)
        btn_frame.pack(pady=5)

        ttk.Button(btn_frame, text="📂 Open File", command=self.open_file, bootstyle=PRIMARY).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="🚀 Compile", command=self.compile_code, bootstyle=SUCCESS).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="❌ Exit", command=self.root.quit, bootstyle=DANGER).pack(side=tk.LEFT, padx=5)

    def open_file(self):
        file_path = filedialog.askopenfilename(filetypes=[("C Files", "*.c"), ("All Files", "*.*")])
        if file_path:
            with open(file_path, 'r') as f:
                self.code_input.delete(1.0, tk.END)
                self.code_input.insert(tk.END, f.read())
            self.log_info(f"Opened file: {file_path}")

    def compile_code(self):
        with open("temp_input.c", "w") as f:
            f.write(self.code_input.get(1.0, tk.END))

        self.output_area.delete(1.0, tk.END)
        self.log_info("⏳ Compilation started...\n")

        try:
            result = subprocess.run(["compiler.exe", "temp_input.c"], capture_output=True, text=True,  encoding="utf-8", errors="replace")

            if result.stdout:
                if "error:" in result.stdout.lower():
                    self.log_error("❌ Semantic Error:\n" + result.stdout)
                else:
                    self.log_success("✅ Compiler Output:\n" + result.stdout)


            if result.stderr:
                self.log_error("❌ Compiler Errors:\n" + result.stderr)

            if os.path.exists("ast.dot"):
                self.log_info("Generating AST image with Graphviz...")
                dot_result = subprocess.run(["dot", "-Tpng", "ast.dot", "-o", "ast.png"], capture_output=True, text=True)
                if dot_result.returncode == 0:
                    self.wait_for_image("ast.png")
                else:
                    self.log_error("❌ Graphviz error:\n" + dot_result.stderr)
            else:
                self.log_warning("⚠️ ast.dot not found. AST may not have been generated.")

        except Exception as e:
            self.log_error(f"❌ Error running compiler: {e}")

    def wait_for_image(self, image_path):
        max_retries = 5
        for attempt in range(max_retries):
            try:                                                       #with this the prog catches zeroDivisionError hence no crashing                   
                if os.path.exists(image_path):                         #cheking that image exists
                    img = Image.open(image_path)                       #open image
                    img.load()  # fully load the image
                    img = img.resize((650, 400), Resampling.LANCZOS)
                    self.ast_img = ImageTk.PhotoImage(img)
                    self.ast_label.config(image=self.ast_img, text="")
                    self.log_info("🌳 AST image loaded successfully.")
                    return
            except UnidentifiedImageError:
                self.log_warning(f"⏳ Retrying... AST not ready ({attempt+1}/{max_retries})")
            except Exception as e:
                self.log_warning(f"⚠️ Error loading image: {e}")
            time.sleep(0.5)

        self.ast_label.config(text="⚠️ Failed to load AST image.")
        self.log_error("❌ Failed to open ast.png after Graphviz generation.")

    # --- Logging with color themes ----
    def log_info(self, message):    #logging functions displaying msg in output with diff colour
        self.output_area.insert(tk.END, message + "\n", "info")
        self.output_area.tag_config("info", foreground="#00BFFF")

    def log_success(self, message):
        self.output_area.insert(tk.END, message + "\n", "success")
        self.output_area.tag_config("success", foreground="#00FF7F")

    def log_error(self, message):
        self.output_area.insert(tk.END, message + "\n", "error")
        self.output_area.tag_config("error", foreground="#FF5555")

    def log_warning(self, message):
        self.output_area.insert(tk.END, message + "\n", "warn")
        self.output_area.tag_config("warn", foreground="#FFD700")

# === Launch ===
# == Launch ==
if __name__ == "__main__":
    app = ttk.Window(themename="darkly")  # try also: "flatly", "cyborg", "pulse", etc.
    MiniCCompilerApp(app)
    app.mainloop()

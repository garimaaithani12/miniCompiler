# miniCompiler

A simple educational compiler for a subset of the C language, built using **Lex** (Flex), **Yacc** (Bison), and a Python GUI powered by **Tkinter** and **ttkbootstrap**. This project demonstrates the complete compilation pipeline from source code to:

- ✅ Lexical Analysis
- ✅ Parsing and AST generation
- ✅ Semantic Checks
- ✅ Three Address Code (3AC) Generation
- ✅ Pseudo Assembly Code Generation
- ✅ AST Visualization (with Graphviz)
- ✅ Beautiful step-by-step GUI Output

---

## 🔧 Features

- 📄 **C-like Syntax Support**: Supports `int`, variable declarations, assignments, arithmetic expressions, and `return`.
- ⚙️ **3-Address Code (3AC)**: Generates intermediate code with temporary variables.
- 🧑‍💻 **Assembly Generation**: Converts 3AC to simple pseudo-assembly.
- 🌳 **AST Visualization**: Automatically generates and displays an `ast.png` using Graphviz.
- 🎨 **Modern GUI**: Includes a Python GUI built with `ttkbootstrap` to step through each compiler phase visually.

---

## 📁 Project Structure


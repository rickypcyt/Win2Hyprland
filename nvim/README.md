# 🚀 Configuración de Neovim

Bienvenido a mi configuración personalizada de Neovim. Este setup está diseñado para ser productivo, rápido y visualmente atractivo.

## ✨ Características Principales

- 🎨 Tema Cyberdream con fondo transparente
- ⚡ Navegación rápida entre archivos y buffers
- 🧠 Autocompletado inteligente con nvim-cmp
- 🔍 Búsqueda potente con Telescope
- 📊 Integración con Git
- 📝 Edición mejorada con múltiples plugins
- 🎯 Navegación mejorada con Hop y Harpoon
- 🧩 Soporte para múltiples lenguajes con LSP

## 🎨 Tema

- **Tema principal**: [Cyberdream](https://github.com/scottmckendry/cyberdream.nvim)
- Fondo transparente para una mejor integración con la terminal

## ⌨️ Atajos de Teclado

### Modos de Neovim

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `F13` (CapsLock) | Normal → Inserción | Activa el modo inserción |
| `F13` (CapsLock) | Inserción → Normal | Vuelve al modo normal |
| `Esc` | Cualquier modo | Vuelve al modo normal |

### Navegación Básica

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `h` | Normal | Mover cursor a la izquierda |
| `j` | Normal | Mover cursor abajo |
| `k` | Normal | Mover cursor arriba |
| `l` | Normal | Mover cursor a la derecha |
| `w` | Normal | Saltar al inicio de la siguiente palabra |
| `b` | Normal | Retroceder al inicio de la palabra anterior |
| `e` | Normal | Saltar al final de la palabra actual/siguiente |
| `0` | Normal | Ir al inicio de la línea |
| `^` | Normal | Ir al primer carácter no vacío de la línea |
| `$` | Normal | Ir al final de la línea |
| `gg` | Normal | Ir a la primera línea del archivo |
| `G` | Normal | Ir a la última línea del archivo |
| `:{número}` | Normal | Ir a la línea específica |
| `Ctrl + u` | Normal | Desplazarse media pantalla hacia arriba |
| `Ctrl + d` | Normal | Desplazarse media pantalla hacia abajo |
| `Ctrl + b` | Normal | Retroceder una pantalla completa |
| `Ctrl + f` | Normal | Avanzar una pantalla completa |
| `zz` | Normal | Centrar la pantalla en la línea actual |
| `zt` | Normal | Llevar la línea actual al tope de la pantalla |
| `zb` | Normal | Llevar la línea actual al fondo de la pantalla |

### Ventanas y Pestañas

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `Ctrl + h` | Normal | Moverse a la ventana izquierda |
| `Ctrl + j` | Normal | Moverse a la ventana inferior |
| `Ctrl + k` | Normal | Moverse a la ventana superior |
| `Ctrl + l` | Normal | Moverse a la ventana derecha |
| `:vsplit [archivo]` | Normal | Dividir ventana verticalmente |
| `:split [archivo]` | Normal | Dividir ventana horizontalmente |
| `Ctrl + w v` | Normal | Dividir ventana verticalmente |
| `Ctrl + w s` | Normal | Dividir ventana horizontalmente |
| `Ctrl + w c` | Normal | Cerrar ventana actual |
| `Ctrl + w o` | Normal | Cerrar otras ventanas |
| `Ctrl + w =` | Normal | Igualar tamaño de ventanas |
| `Ctrl + w _` | Normal | Maximizar altura de la ventana |
| `Ctrl + w \|` | Normal | Maximizar ancho de la ventana |
| `:tabnew [archivo]` | Normal | Nueva pestaña |
| `gt` | Normal | Siguiente pestaña |
| `gT` | Normal | Pestaña anterior |
| `{n}gt` | Normal | Ir a la pestaña número `n` |

### Edición de Texto

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `i` | Normal | Insertar antes del cursor |
| `a` | Normal | Insertar después del cursor |
| `I` | Normal | Insertar al inicio de la línea |
| `A` | Normal | Insertar al final de la línea |
| `o` | Normal | Insertar línea debajo |
| `O` | Normal | Insertar línea encima |
| `x` | Normal | Eliminar carácter bajo el cursor |
| `dd` | Normal | Cortar línea actual |
| `yy` | Normal | Copiar línea actual |
| `p` | Normal | Pegar después del cursor |
| `P` | Normal | Pegar antes del cursor |
| `u` | Normal | Deshacer |
| `Ctrl + r` | Normal | Rehacer |
| `.` | Normal | Repetir último comando |
| `r` | Normal | Reemplazar un carácter |
| `R` | Normal | Modo reemplazo |
| `~` | Normal | Cambiar mayúsculas/minúsculas |
| `>>` | Normal | Aumentar indentación |
| `<<` | Normal | Disminuir indentación |
| `==` | Normal | Autoindentar línea |
| `gq` | Visual | Formatear texto seleccionado |
| `gqap` | Normal | Formatear párrafo |
| `Ctrl + a` | Normal/Visual | Seleccionar todo el contenido |

### Búsqueda y Reemplazo

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `/texto` | Normal | Buscar "texto" hacia adelante |
| `?texto` | Normal | Buscar "texto" hacia atrás |
| `n` | Normal | Siguiente coincidencia |
| `N` | Normal | Coincidencia anterior |
| `*` | Normal | Buscar palabra bajo el cursor hacia adelante |
| `#` | Normal | Buscar palabra bajo el cursor hacia atrás |
| `:s/viejo/nuevo` | Normal | Reemplazar primera coincidencia en la línea |
| `:s/viejo/nuevo/g` | Normal | Reemplazar todas las coincidencias en la línea |
| `:%s/viejo/nuevo/g` | Normal | Reemplazar en todo el archivo |
| `:s/\<el\>/los/g` | Normal | Reemplazar palabras completas |

### Manejo de Archivos

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `:e archivo` | Normal | Editar archivo |
| `:w` | Normal | Guardar archivo |
| `:w!` | Normal | Forzar guardado |
| `:q` | Normal | Cerrar ventana |
| `:q!` | Normal | Cerrar sin guardar |
| `:wq` o `:x` | Normal | Guardar y salir |
| `:wq!` | Normal | Forzar guardado y salida |
| `:e!` | Normal | Recargar archivo (descartar cambios) |
| `:saveas ruta` | Normal | Guardar como |
| `Ctrl + s` | Normal/Inserción | Guardar archivo actual |

### Buffers

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `:ls` | Normal | Listar buffers abiertos |
| `:b[n]` | Normal | Ir al buffer número n |
| `:bpre` | Normal | Buffer anterior |
| `:bnext` | Normal | Siguiente buffer |
| `:bfirst` | Normal | Primer buffer |
| `:blast` | Normal | Último buffer |
| `:bd` | Normal | Cerrar buffer actual |
| `:bd!` | Normal | Forzar cierre del buffer |
| `Ctrl + Shift + ←/→` | Normal | Navegar entre buffers |

### Plugins - Telescope (Búsqueda)

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `Espacio + ff` | Normal | Buscar archivos |
| `Espacio + fg` | Normal | Buscar texto en archivos (live grep) |
| `Espacio + fb` | Normal | Buscar en buffers abiertos |
| `Espacio + fh` | Normal | Buscar en el historial de archivos |
| `Espacio + fo` | Normal | Buscar en archivos abiertos recientemente |
| `Espacio + fw` | Normal | Buscar palabra bajo el cursor |

### Plugins - NvimTree (Explorador de archivos)

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `Espacio + e` | Normal | Mostrar/ocultar NvimTree |
| `Espacio + m` | Normal | Abrir NvimTree en el archivo actual |
| `a` | NvimTree | Crear archivo/carpeta |
| `d` | NvimTree | Eliminar archivo/carpeta |
| `r` | NvimTree | Renombrar archivo/carpeta |
| `y` | NvimTree | Copiar nombre/ruta |
| `x` | NvimTree | Cortar archivo |
| `p` | NvimTree | Pegar archivo |
| `R` | NvimTree | Refrescar árbol |
| `-` | NvimTree | Navegar hacia arriba |
| `s` | NvimTree | Abrir en split horizontal |
| `i` | NvimTree | Abrir en split vertical |
| `t` | NvimTree | Abrir en nueva pestaña |

### Plugins - Harpoon (Navegación Rápida)

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `Espacio + ha` | Normal | Añadir archivo actual a Harpoon |
| `Espacio + hm` | Normal | Mostrar menú de Harpoon |
| `Espacio + 1` | Normal | Ir al archivo 1 de Harpoon |
| `Espacio + 2` | Normal | Ir al archivo 2 de Harpoon |
| `Espacio + 3` | Normal | Ir al archivo 3 de Harpoon |
| `Espacio + 4` | Normal | Ir al archivo 4 de Harpoon |

### Plugins - Hop (Navegación Rápida en Texto)

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `s` | Normal | Saltar a una palabra en el archivo |
| `S` | Normal | Saltar a una línea en el archivo |
| `t` | Normal | Saltar a un carácter antes del objetivo |
| `f` | Normal | Saltar a un carácter |

### Plugins - Comentarios (Comment.nvim)

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `gcc` | Normal | Comentar/descomentar línea actual |
| `gc` | Visual | Comentar/descomentar selección |
| `gbc` | Normal | Comentar/descomentar bloque de código |
| `gco` | Normal | Insertar comentario en la línea siguiente |
| `gcO` | Normal | Insertar comentario en la línea anterior |
| `gcA` | Normal | Añadir comentario al final de la línea |

### Plugins - Plegado de Código (UFO)

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `zR` | Normal | Expandir todos los pliegues |
| `zM` | Normal | Contraer todos los pliegues |
| `za` | Normal | Alternar pliegue actual |
| `zA` | Normal | Alternar pliegue actual recursivamente |
| `zc` | Normal | Cerrar pliegue actual |
| `zC` | Normal | Cerrar pliegue actual recursivamente |
| `zo` | Normal | Abrir pliegue actual |
| `zO` | Normal | Abrir pliegue actual recursivamente |
| `zj` | Normal | Mover al siguiente pliegue cerrado |
| `zk` | Normal | Mover al pliegue cerrado anterior |

### Plugins - Git (Fugitive y Gitsigns)

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `:G` | Normal | Abrir interfaz de Git (Fugitive) |
| `:Gstatus` | Normal | Mostrar estado de Git |
| `:Gdiff` | Normal | Mostrar diferencias |
| `:Gblame` | Normal | Mostrar quién modificó cada línea |
| `:Glog` | Normal | Mostrar historial de commits |
| `:Gcommit` | Normal | Hacer commit |
| `:Gpush` | Normal | Hacer push |
| `:Gpull` | Normal | Hacer pull |
| `]c` | Normal | Siguiente cambio |
| `[c` | Normal | Cambio anterior |

### Plugins - LSP (Language Server Protocol)

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `gd` | Normal | Ir a la definición |
| `gD` | Normal | Ir a la declaración |
| `K` | Normal | Mostrar documentación |
| `gi` | Normal | Ir a la implementación |
| `gr` | Normal | Mostrar referencias |
| `gt` | Normal | Ir a la definición de tipo |
| `F2` | Normal | Renombrar símbolo |
| `]d` | Normal | Ir al siguiente diagnóstico |
| `[d` | Normal | Ir al diagnóstico anterior |
| `gl` | Normal | Mostrar diagnóstico en línea |
| `:Format` | Normal | Formatear documento |
| `:CodeAction` | Normal | Mostrar acciones de código disponibles |

### Plugins - LSP Signature (Firmas de Funciones)

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `K` | Normal | Mostrar documentación de la función |
| `<C-k>` | Insertar | Mostrar firma de la función |
| `]h` | Normal | Siguiente parámetro |
| `[h` | Normal | Parámetro anterior |

### Modo Visual

| Atajo | Modo | Descripción |
|-------|------|-------------|
| `v` | Normal | Entrar en modo visual |
| `V` | Normal | Seleccionar líneas |
| `Ctrl + v` | Normal | Seleccionar en bloque |
| `o` | Visual | Cambiar extremo de la selección |
| `O` | Visual | Cambiar extremo de la selección en bloque |
| `aw` | Visual | Seleccionar palabra |
| `as` | Visual | Seleccionar oración |
| `ap` | Visual | Seleccionar párrafo |
| `ab` | Visual | Seleccionar bloque entre paréntesis |
| `aB` | Visual | Seleccionar bloque entre llaves |
| `>` | Visual | Aumentar indentación |
| `<` | Visual | Disminuir indentación |
| `y` | Visual | Copiar selección |
| `d` o `x` | Visual | Cortar selección |
| `p` | Visual | Pegar reemplazando selección |
| `u` | Visual | Convertir a minúsculas |
| `U` | Visual | Convertir a mayúsculas |
| `~` | Visual | Cambiar mayúsculas/minúsculas |
| `J` | Visual | Unir líneas |

### Comandos Útiles

| Comando | Descripción |
|---------|-------------|
| `:noh` | Limpiar resaltado de búsqueda |
| `:set number` | Mostrar números de línea |
| `:set relativenumber` | Mostrar números de línea relativos |
| `:set nowrap` | Desactivar ajuste de línea |
| `:set wrap` | Activar ajuste de línea |
| `:set list` | Mostrar caracteres invisibles |
| `:set nolist` | Ocultar caracteres invisibles |
| `:set spell` | Activar corrección ortográfica |
| `:set nospell` | Desactivar corrección ortográfica |
| `:set paste` | Modo pegado (desactiva indentación automática) |
| `:set nopaste` | Salir del modo pegado |
| `:set hlsearch` | Resaltar resultados de búsqueda |
| `:set nohlsearch` | Desactivar resaltado de búsqueda |
| `:set ignorecase` | Búsqueda insensible a mayúsculas |
| `:set smartcase` | Búsqueda inteligente de mayúsculas |
| `:set tabstop=4` | Establecer tamaño de tabulación a 4 espacios |
| `:set shiftwidth=4` | Establecer tamaño de indentación a 4 espacios |
| `:set expandtab` | Usar espacios en lugar de tabuladores |
| `:retab` | Convertir tabuladores a espacios |
| `:mksession archivo.vim` | Guardar sesión actual |
| `:source archivo.vim` | Cargar sesión guardada |

## 🧩 Plugins Instalados

### Navegación

- **Telescope.nvim** - Búsqueda de archivos, live grep, etc.
- **NvimTree** - Explorador de archivos
- **Harpoon** - Navegación rápida entre archivos frecuentes
- **Hop** - Navegación por palabras y líneas

### Apariencia

- **Cyberdream** - Tema de colores
- **Bufferline** - Pestañas de buffers
- **Indent-blankline** - Líneas de indentación
- **Lualine** - Barra de estado

### Edición

- **nvim-cmp** - Autocompletado
- **nvim-surround** - Manipulación de paréntesis, comillas, etc.
- **nvim-autopairs** - Cierre automático de paréntesis y comillas
- **Comment.nvim** - Comentarios inteligentes
- **nvim-ufo** - Plegado de código mejorado

### Git

- **vim-fugitive** - Integración con Git
- **gitsigns.nvim** - Marcadores de Git en el margen

### LSP y Sintaxis

- **nvim-treesitter** - Resaltado de sintaxis mejorado
- **lsp_signature** - Firma de funciones
- **nvim-lspconfig** - Configuración de LSP

## ⚙️ Requisitos

- Neovim 0.8.0 o superior
- Nerd Font instalada (recomendado: FiraCode Nerd Font)
- Node.js (para algunos servidores LSP)
- Git


## 🛠️ Personalización

- `init.lua` - Configuración principal
- `lua/plugins.lua` - Configuración de plugins
- `lua/keymaps.lua` - Atajos de teclado personalizados
- `lua/options.lua` - Opciones de Neovim

## 📝 Licencia

MIT
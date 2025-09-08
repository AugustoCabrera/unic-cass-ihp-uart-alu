

# Implementar una interfaz de comunicación UART para la unidad


Comunicación serie permitirá proporcionar a la ALU
los operandos y el operador a través del puerto serie (RX), y transmitir el resultado por la misma vía (TX).

<p align="center">
    <img src="img/image1.png" alt="bloq">
</p>

---

# Marco Teorico

### UART (Transmisor-Receptor Asíncrono Universal)

Es un protocolo simple de dos cables utilizado para intercambiar datos en serie.

- **Asíncrono** significa que no hay un reloj compartido entre los dispositivos. Para que el UART funcione correctamente, es necesario que ambos lados de la conexión estén configurados con la misma velocidad de baudios o bits por segundo.
  
- **Bits de inicio y parada**: Se utilizan para indicar dónde comienzan y terminan los datos del usuario, permitiendo «tramar» los datos.

- **Bit de paridad**: Opcionalmente, se puede emplear un bit de paridad para detectar errores en un solo bit.

Aunque el **UART** sigue siendo ampliamente utilizado, en los últimos años ha sido reemplazado en algunas aplicaciones por tecnologías como **SPI**, **I2C**, **USB** y **Ethernet**.

#### Funcionamiento

<p align="center">
    <img src="img/image2.png" alt="bloq">
</p>


El protocolo UART funciona de la siguiente manera, tanto para transmitir como para recibir datos:

1. **Detección de transición**: Inicialmente, la línea se encuentra en 1, lo que indica que no hay comunicación. Cuando se desea transmitir, la línea baja a 0 para comenzar la transmisión.

2. **Muestreo de los datos entrantes**: Tras finalizar el tiempo del bit de inicio, se empieza a transmitir el byte completo, comenzando por el **bit de menor peso (LSB)**. Al final, se envía el bit de paridad, que permite verificar si la información transmitida y recibida es correcta.

3. **Muestreo del bit de parada**: Este bit es necesario para indicar que se ha completado la transmisión o recepción de los datos.

El truco de este protocolo es muestrear cada bit justo en la mitad de su período. Esto asegura que no haya ambigüedades en la información. En una **FPGA**, se debe tener cuidado al muestrear, asegurándose de hacerlo justo en el flanco de subida de la señal de muestreo.

### Generación de Ticks

**Baud Rate:** Es la velocidad de transmisión de datos, medida en símbolos por segundo. Por ejemplo, un Baud Rate de 19,200 significa que se transmiten 19,200 símbolos por segundo.

- Para un Baud Rate de 19,200 bps, se necesitan **16 muestras** _(TICKS)_ por cada bit transmitido. Esto se hace para asegurar que se captura la señal en diferentes momentos a lo largo de cada bit, lo que permite una mejor detección de los estados de la señal.

- La frecuencia de muestreo se calcula como:
  - Frecuencia de muestreo = Baud Rate × 16
  - Frecuencia de muestreo = 19,200 bps × 16 = 307,200 ticks por segundo

#### Relación con el Clock de la Placa

- Si el reloj de la placa es de **100 MHz**, significa que el reloj genera **100,000,000 ciclos** por segundo. Para determinar cuántos ciclos de reloj se necesitan para generar un tick, se puede hacer el siguiente cálculo:
  - Ciclos de reloj por tick = Frecuencia del reloj / Frecuencia de muestreo
  - Ciclos de reloj por tick = 100,000,000 Hz / 307,200 ticks por segundo ≈ 326 ciclos de reloj

#### Generador de Baud Rate

El módulo `baud_rate` tiene como objetivo generar una señal de sincronización periódica, llamada `tick`, a una frecuencia más baja que la del reloj de entrada.

- El **Baud Rate Generator** es un contador que cuenta hasta **163** (el número de ciclos de reloj necesarios para generar un tick) y se reinicia. Cuando el contador alcanza este valor, genera un tick (señal de muestreo).

- Este contador puede ser implementado en Verilog o en hardware de otras formas. Cada vez que el contador se reinicia, indica que ha pasado el tiempo necesario para muestrear un bit de datos.

#### RESUMEN:

1. **Baud Rate** de 19,200 bps requiere 16 muestras por bit, lo que resulta en una frecuencia de muestreo de 307,200 ticks por segundo.
2. Con un reloj de 50 MHz, cada tick se genera cada 163 ciclos de reloj.
3. El Baud Rate Generator cuenta hasta 163 para generar los ticks necesarios para la transmisión UART.

Esto asegura que el sistema UART sea capaz de leer y transmitir datos de manera precisa y confiable.

---

# Implementación

La función principal del módulo de comunicación serie de la PC es transmitir los bits de cada byte de forma individual. El módulo UART desarrollado recibe estos bits en una cola FIFO de RX, donde se reensamblan para formar los bytes completos, y luego los envía a la ALU.

Una vez que la ALU realiza la operación, el resultado se coloca en la cola FIFO de TX y es transmitido por el puerto serie a la PC, que espera estos datos. Esto se representa con el siguiente diagrama:


<p align="center">
  <img src="img/image3.png" alt="bloq">
</p>

<p align="center">
  <img src="img/image12.png" alt="bloq">
</p>

La máquina de estados está representada por un módulo de interfaz entre la ALU y el módulo UART, así como el módulo FIFO que gestiona la lectura y escritura de datos. El sistema está compuesto por cuatro máquinas de estado interrelacionadas. A continuación se describen cada una de estas máquinas:

1. **Máquina de Estado del Transmisor UART**: Controla el proceso de transmisión de datos a través de UART, asegurando la correcta secuenciación de los bits de datos y el control de las señales de inicio y parada.

<p align="center">
    <img src="img/image5.png" alt="bloq">
</p>

2. **Máquina de Estado del Receptor UART**: Se encarga de recibir los datos a través de UART, gestionando la detección del inicio de la transmisión, la captura de los bits de datos y la señalización de que se ha completado la recepción.

<p align="center">
    <img src="img/image4.png" alt="bloq">
</p>

3. **Máquina de Estado de la FIFO**: Administra la lectura y escritura de datos en la memoria FIFO, controlando los punteros de lectura y escritura, y generando las señales que indican si la FIFO está llena o vacía.

<p align="center">
    <img src="img/image6.png" alt="bloq">
</p>


4. **Máquina de Estado de la Interfaz ALU-UART**: Coordina la interacción entre la ALU y el módulo UART, gestionando la lectura de datos desde la FIFO, la selección de operaciones de la ALU y la escritura de resultados de vuelta en la FIFO.

<p align="center">
    <img src="img/image7.png" alt="bloq">
</p>

Estos grafos reflejan la lógica de control y los eventos que conducen a los cambios de estado en cada uno de los módulos, permitiendo una comunicación efectiva y sinérgica entre la ALU y el módulo UART.

## Posibles Mejoras Futuras

Se podrían agregar los estados **_verify_** y **_error_** en futuras versiones para mejorar la gestión del sistema:

### Estado de Error

En algunos sistemas, cuando se detectan errores de paridad o se excede el tiempo de espera (_timeout_) sin recibir datos, es posible definir un estado de error o _timeout_. Este estado se utiliza para gestionar la corrección del error o iniciar un nuevo intento de transmisión.

### Estado de Verificación (Parity Bit)

Si se utiliza paridad, se transmite un bit adicional para verificar la corrección de los datos enviados. Este bit de paridad puede ser par o impar, dependiendo de la configuración establecida, y permite detectar errores en los datos recibidos.


## Esquema de Diseño (Schematic)

Representación gráfica que proporciona una visión detallada de las conexiones dentro del diseño digital. A través de esta herramienta, los diseñadores pueden:

- Ver una representación gráfica de la lista de conexiones.
- Revisar las puertas, jerarquías y conectividad de los componentes.
- Trazar y ampliar conos de lógica para un análisis más profundo.
- Analizar el diseño para identificar posibles mejoras o errores.
- Comprender mejor los procesos que ocurren dentro del diseño.

A continuación, se presenta el esquemático de todo el programa:

<p align="center">
    <img src="img/image8.png" alt="bloq">
</p>

<p align="center">
    <img src="img/image9.png" alt="bloq">
</p>

---

# Constraints

El archivo `constraints.xdc` define cómo se asignan las señales lógicas del diseño a los pines físicos de la FPGA en la tarjeta Basys 3, además de establecer otras propiedades, como la frecuencia del reloj y los estándares de entrada/salida. En este caso, los pines B18 y A18 se utilizan para la recepción y transmisión de datos, respectivamente. Los LEDs, desde V14 hasta U16 (de MSB a LSB), muestran el resultado que la ALU transmite a la computadora. El botón central se utiliza para reiniciar el sistema. A continuación, se muestra gráficamente la asignación de los pines utilizados:



<p align="center">
    <img src="img/image11.png" alt="bloq">
</p>

---

# Test Bench Baud Rate


Este test bench verifica el funcionamiento del módulo `baud_rate`.

### Señales de Prueba

- **i_clk**: Señal de reloj de entrada.
- **i_reset**: Señal de reset.
- **o_tick**: Salida que indica cuándo se genera un tick.

### Funcionamiento

1. **Generador de Reloj**: Alterna la señal de reloj a 50 MHz (cada 10 ns).
2. **Proceso de Reset**: Activa el reset al inicio y lo mantiene por 30 ns.
3. **Contador de Ciclos**: Cuenta ciclos de reloj hasta que se genera un tick, mostrando el tiempo y el conteo cada vez que ocurre.
4. **Monitorización**: Imprime el estado del reset y el tick en cada instante relevante.

### Resultado Esperado

El test bench permite observar el conteo de ciclos de reloj y la generación de ticks, confirmando el correcto funcionamiento del módulo `baud_rate`.

<p align="center">
    <img src="img/image10.png" alt="bloq">
</p>

---

# ANEXO: Video

En el siguiente enlace se presenta la prueba física implementada en la FPGA para las siguientes operaciones: [Drive](https://drive.google.com/file/d/14sBGQRX6rywuFxsSzoS647pQEIHfOVoQ/view?usp=sharing)


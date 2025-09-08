import sys
import serial
import serial.tools.list_ports
from typing import Optional

BAUDRATE = 19200  # Set baud rate for communication

OPCODES = {
    'ADD': 0x20,
    'SUB': 0x22,
    'AND': 0x24,
    'OR':  0x25,
    'XOR': 0x26,
    'NOR': 0x27,
    'SRA': 0x03,
    'SRL': 0x020
}

EXIT_COMMANDS = {'q', 'quit', 'e', 'exit'}


class SerialPortControl:
    def __init__(self, port: str) -> None:
        try:
            self.serial_port = serial.Serial(port, BAUDRATE, timeout=1)
        except serial.SerialException as e:
            print(f"Error opening serial port: {e}")
            sys.exit(1)

    def send_serial_data(self) -> None:
        while True:
            operand1 = self.get_operand("Operand 1 (Signed 8-bit integer): ")
            if operand1 is None:
                break

            operand2 = self.get_operand("Operand 2 (Signed 8-bit integer): ")
            if operand2 is None:
                break

            operation = self.get_operation()
            if operation is None:
                break

            self.send_data(operation, operand1, operand2)
            self.receive_result()

    def get_operand(self, prompt: str) -> Optional[int]:
        operand_str: str = input(f'{prompt}').lower()
        if operand_str in EXIT_COMMANDS:
            self.exit_program()

        try:
            operand: int = int(operand_str)
            if -128 <= operand <= 127:
                return operand & 0xFF  # Convert to 8-bit two's complement
            else:
                print('Error: Operand must be a signed 8-bit integer (-128 to 127)')
                return None
        except ValueError:
            print('Error: Please enter a valid signed 8-bit integer.')
            return None

    def get_operation(self) -> Optional[int]:
        operation: str = input('Select operation (ADD, SUB, AND, OR, XOR, NOR, SRA, SRL): ').lower()
        if operation in EXIT_COMMANDS:
            self.exit_program()

        if operation.upper() in OPCODES:
            return OPCODES[operation.upper()]
        else:
            print('Invalid operation')
            return None

    def send_data(self, operation: int, operand1: int, operand2: int) -> None:
        data_to_send: bytes = bytes([operation, operand1, operand2])
        self.serial_port.write(data_to_send)

    def receive_result(self) -> None:
        received_data: bytes = self.serial_port.read(1)
        if len(received_data) == 1:
            result: int = int.from_bytes(received_data, byteorder='big', signed=True)
            print('Result:', result)
        else:
            print('Reception error: No data received')

    def exit_program(self) -> None:
        print('Exiting...')
        self.serial_port.close()
        sys.exit()

def select_serial_port() -> Optional[str]:
    ports = serial.tools.list_ports.comports()
    port_list: list[str] = []

    print("\nAVAILABLE PORTS:")
    for i, port in enumerate(ports):
        print(f"{i}: {port.device}")
        port_list.append(port.device)

    try:
        selected_port_index: int = int(input("Select port number: "))
        if 0 <= selected_port_index < len(port_list):
            selected_port: str = port_list[selected_port_index]
            print(f"Selected port: {selected_port}")
            return selected_port
        else:
            print("Port selection out of range.")
            return None
    except ValueError:
        print("Invalid input. Please enter a valid number.")
        return None


if __name__ == "__main__":
    selected_port: Optional[str] = select_serial_port()
    if selected_port:
        app = SerialPortControl(selected_port)
        app.send_serial_data()  # Continuously send operations until exit command is entered

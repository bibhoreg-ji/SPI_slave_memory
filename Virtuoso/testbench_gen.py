import ipywidgets as widgets
from IPython.display import display, HTML

def construct_vams(packets_15):
    """Generates the full Verilog-AMS code based on 15-bit packets."""
    header = """`include "disciplines.vams"
`include "constants.vams"

module spi_driver_seq(sclk, cs, mosi, rst_n);

    input sclk;
    output cs, mosi, rst_n;
    electrical sclk, cs, mosi, rst_n;

    parameter real vhigh = 1.8;
    parameter real vlow  = 0.0;
    parameter real v_thresh = 0.9;
    parameter real tt = 1e-9;

    integer bit_count;
    integer active;

    real cs_val, mosi_val, rst_val;

    analog begin

        // INIT
        @(initial_step) begin
            cs_val = 1;
            mosi_val = 0;
            rst_val = 0;
            bit_count = 0;
            active = 0;
        end
        @(timer(200e-9))   rst_val = 1;
       // @(timer(22000e-9)) rst_val = 0;

        // ============================
        // WRITE BURSTS (ADDR 0-4)
        // ============================
        @(timer(500e-9))   begin active=1; cs_val=0; bit_count=0; mosi_val=vhigh; end
        @(timer(2500e-9))  begin active=1; cs_val=0; bit_count=0; mosi_val=vhigh; end
        @(timer(4500e-9))  begin active=1; cs_val=0; bit_count=0; mosi_val=vhigh; end
        @(timer(6500e-9))  begin active=1; cs_val=0; bit_count=0; mosi_val=vhigh; end
        @(timer(8500e-9))  begin active=1; cs_val=0; bit_count=0; mosi_val=vhigh; end

        // ============================
        // READ BURSTS (ADDR 0-4)
        // ============================
        @(timer(11500e-9)) begin active=1; cs_val=0; bit_count=0; mosi_val=vlow; end
        @(timer(13500e-9)) begin active=1; cs_val=0; bit_count=0; mosi_val=vlow; end
        @(timer(15500e-9)) begin active=1; cs_val=0; bit_count=0; mosi_val=vlow; end
        @(timer(17500e-9)) begin active=1; cs_val=0; bit_count=0; mosi_val=vlow; end
        @(timer(19500e-9)) begin active=1; cs_val=0; bit_count=0; mosi_val=vlow; end

        // ============================
        // MOSI GENERATION
        // ============================
        @(cross(V(sclk) - v_thresh, -1)) begin
            if (active == 1) begin
                bit_count = bit_count + 1;

                // ================= WRITE =================
                if ($abstime < 10500e-9) begin
"""
    write_logic = ""
    for i, p in enumerate(packets_15):
        t_limit = 2500 + (i * 2000)
        prefix = "                    if" if i == 0 else "                    else if"
        if i == 4: prefix = "                    else"

        write_logic += f"{prefix} ($abstime < {t_limit}e-9) begin\n" if i < 4 else f"{prefix} begin\n"
        write_logic += "                        case(bit_count)\n"
        for idx, bit in enumerate(p):
            v = "vhigh" if bit == '1' else "vlow"
            write_logic += f"                            {idx+1}: mosi_val={v};\n"
        write_logic += "                            default: mosi_val=vlow;\n"
        write_logic += "                        endcase\n"
        write_logic += "                    end\n"

    read_header = """                end
                // ================= READ =================
                else begin
"""
    read_logic = ""
    for i, p in enumerate(packets_15):
        t_limit = 13500 + (i * 2000)
        prefix = "                    if" if i == 0 else "                    else if"
        if i == 4: prefix = "                    else"

        read_logic += f"{prefix} ($abstime < {t_limit}e-9) begin\n" if i < 4 else f"{prefix} begin\n"
        read_logic += "                        case(bit_count)\n"
        # Mapping fixed address (first 7 bits of the 15-bit packet)
        for idx in range(7):
            v = "vhigh" if p[idx] == '1' else "vlow"
            read_logic += f"                            {idx+1}: mosi_val={v};\n"
        read_logic += "                            default: mosi_val=vlow;\n"
        read_logic += "                        endcase\n"
        read_logic += "                    end\n"

    footer = """                end
            end
        end

        // END TRANSACTION
        @(cross(V(sclk) - v_thresh, +1)) begin
            if (active==1 && bit_count>=16) begin
                active=0;
                cs_val=1;
                mosi_val=vlow;
            end
        end

        // OUTPUTS
        V(cs)    <+ transition(cs_val ? vhigh : vlow, 0, tt);
        V(mosi)  <+ transition(mosi_val, 0, tt);
        V(rst_n) <+ transition(rst_val ? vhigh : vlow, 0, tt);

    end
endmodule
"""
    return header + write_logic + read_header + read_logic + footer

# --- GUI Logic ---

# Fixed 7-bit addresses for bursts 0-4
fixed_addresses = ["0000000", "0000001", "0000010", "0000011", "0000100"]
data_entries = []

# Output widget for status messages
output_message = widgets.Output()

for i in range(5):
    data_input = widgets.Text(
        value="00000000",
        placeholder='Enter 8-bit data',
        description=f'Addr {fixed_addresses[i]}:',
        disabled=False,
        style={'description_width': 'initial'},
        layout=widgets.Layout(width='300px')
    )
    data_entries.append(data_input)

generate_button = widgets.Button(
    description='Generate .vams File',
    button_style='success',
    tooltip='Click to generate spi_driver_seq.vams',
    icon='file-code'
)

def on_generate_button_clicked(b):
    with output_message:
        output_message.clear_output()
        packets_15 = []
        error_found = False

        for i in range(5):
            data = data_entries[i].value.strip()

            # Validation for 8-bit data
            if len(data) != 8 or not all(bit in '01' for bit in data):
                print(f"Error: Burst {i} (Addr {fixed_addresses[i]}): Data must be exactly 8 bits (0s and 1s).")
                error_found = True
                break

            # Combine fixed 7-bit address + user 8-bit data
            packets_15.append(fixed_addresses[i] + data)

        if not error_found:
            try:
                vams_content = construct_vams(packets_15)
                with open("spi_driver_seq.vams", "w") as f:
                    f.write(vams_content)
                print(f"Success! 'spi_driver_seq.vams' generated with 1-15 bit mapping.")
            except Exception as e:
                print(f"Error: {e}")

generate_button.on_click(on_generate_button_clicked)

# Displaying the GUI
display(HTML("<h2>IISc SPI Stimulus Generator</h2>"))
display(HTML("<p>Enter the 8-bit Data to be written to each fixed address:</p>"))

for entry in data_entries:
    display(entry)

display(generate_button, output_message)

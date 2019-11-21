--------------------------------------------------------------------------------
--
-- Title: Test Bench for Viterbi Decoder Algorithm
--
-- Copyright (c) 1998,1999 by Mentor Graphics Corporation.  All rights reserved.
--
-- This source file may be used and distributed without restriction provided
-- that this copyright statement is not removed from the file and that any
-- derivative work contains this copyright notice.
--
--------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.std_logic_textio.ALL;
USE ieee.math_real.ALL;
USE std.textio.ALL;


ENTITY viterbi_test IS
   GENERIC( clock_delay  : time    := 20 ns;
            err_rate     : real    := 0.10;
            latency      : real    := 1.0;
            random_seed1 : integer := 12345;
            random_seed2 : integer := 67890;
            random_seed3 : integer := 98765;
            random_seed4 : integer := 43210 );
END viterbi_test;

ARCHITECTURE behavioral OF viterbi_test IS

    COMPONENT viterbi
        PORT (
            rst              : IN  std_logic;
            clk              : IN  std_logic;
            data_in          : IN  std_logic_vector( 1 DOWNTO 0 );
            data_out         : OUT std_logic;
            
            --
            --ADDED STUFF HERE----------------------------------------------------------------------
            --
            swindow0         : OUT std_logic_vector( 0 TO 3 );
            distance0        : OUT integer;
            distance1        : OUT integer;
            distance2        : OUT integer;
            distance3        : OUT integer;
            survivors0       : OUT std_logic_vector( 0 TO 3 )
            
        );
    END COMPONENT;

    -- Common signals
    SIGNAL rst                   : std_logic;
    SIGNAL clk                   : std_logic;
    SIGNAL data_in               : std_logic_vector( 1 DOWNTO 0 ) := ( OTHERS => '0' );
    SIGNAL data_out              : std_logic;

    SIGNAL unencoded_sig         : std_logic;
    SIGNAL unencoded_sig_delayed : std_logic;

    SIGNAL err                   : boolean := false;
    SIGNAL err_delayed           : boolean := false;

    SIGNAL sig_in_cnt            : integer := 0;
    SIGNAL err_in_cnt            : integer := 0;

    SIGNAL mismatch              : boolean := false;
    
    --
    --ADDED STUFF HERE------------------------------------------------------------------------------
    --
    SIGNAL swindow0              : std_logic_vector( 0 TO 3 );
    SIGNAL distance0             : integer;
    SIGNAL distance1             : integer;
    SIGNAL distance2             : integer;
    SIGNAL distance3             : integer;
    SIGNAL survivors0            : std_logic_vector( 0 TO 3 );
BEGIN

    -- Instantiate device-under-test.
    dut: viterbi
        PORT MAP( clk              => clk,
                  rst              => rst,
                  data_in          => data_in,
                  data_out         => data_out,
                  
                  --
                  --ADDED STUFF HERE----------------------------------------------------------------
                  --
                  swindow0         => swindow0,
                  distance0        => distance0,
                  distance1        => distance1,
                  distance2        => distance2,
                  distance3        => distance3,
                  survivors0       => survivors0
                  );

    clock_generation:
        PROCESS
        BEGIN
            -- Generate equal duty-cycle clock.
            clk <= '0';
            WAIT FOR ( clock_delay / 2 );
            clk <= '1';
            WAIT FOR ( clock_delay / 2 );
        END PROCESS clock_generation;

    generate_input:
        PROCESS

            VARIABLE data_seed1  : integer := random_seed1;
            VARIABLE data_seed2  : integer := random_seed2;
            VARIABLE error_seed1 : integer := random_seed3;
            VARIABLE error_seed2 : integer := random_seed4;
            VARIABLE unencoded   : std_logic := '0';
            VARIABLE unencoded_1 : std_logic := '0';
            VARIABLE unencoded_2 : std_logic := '0';
            VARIABLE encoded     : std_logic_vector( 1 DOWNTO 0 );

            VARIABLE random_num1 : real := 0.0;
            VARIABLE random_num2 : real := 0.0;

        BEGIN
            -- Initialize input signals.
            data_in <= ( OTHERS => '0' );

            -- Reset the design and wait for 2 clock cycles.
            rst <= '1';
            WAIT FOR clock_delay * 2;
            rst <= '0';

            WAIT FOR clock_delay;

            -- 
            -- Generate random input forever
            -- 
            LOOP
 
                -- Create the random data.
                uniform( data_seed1, data_seed2, random_num1 );
                IF ( random_num1 < 0.5 ) THEN
                    unencoded := '0';
                ELSE
                    unencoded := '1';
                END IF;

                -- Encode the data
                encoded( 1 ) := ( unencoded XOR unencoded_2);                 -- 1 + X^2
                encoded( 0 ) := ( unencoded XOR unencoded_1 XOR unencoded_2); -- 1 + X + X^2

                -- Add errors
                --uniform( error_seed1, error_seed2, random_num2 );
                --IF ( random_num2 < ( err_rate / 2.0 ) ) THEN
                --    err <= true;
                --    encoded( 0 ) := NOT encoded( 0 );
                --    err_in_cnt <= err_in_cnt + 1;
                --ELSIF ( random_num2 < err_rate ) THEN
                --    err <= true;
                --    encoded( 1 ) := NOT encoded( 1 );
                --    err_in_cnt <= err_in_cnt + 1;
                --ELSE
                --    err <= false;
                --END IF;

                -- Send the data
                data_in <= encoded;
                sig_in_cnt <= sig_in_cnt + 1;

                -- Store previous data
                unencoded_sig <= unencoded;
                unencoded_2   := unencoded_1;
                unencoded_1   := unencoded;

                WAIT FOR latency * clock_delay;
 
            END LOOP;

        END PROCESS generate_input;


        unencoded_sig_delayed <= unencoded_sig'DELAYED( ( 18.0 * latency - 0.5 ) * clock_delay );
        err_delayed <= err'DELAYED( ( 18.0 * latency - 0.5 ) * clock_delay );
        mismatch <= NOT( data_out = unencoded_sig_delayed ) AND NOT( clk = '1' );


        process_output:
            PROCESS

                VARIABLE err_out_cnt : integer := 0;
                VARIABLE stdout_buf  : line;
 
            BEGIN

                WAIT FOR clock_delay * 4;

                LOOP

                    WAIT FOR latency * clock_delay;

                    IF ( now > ( 400 ns + ( 18.0 * latency - 0.5 ) * clock_delay ) ) THEN
                        IF ( data_out /= unencoded_sig_delayed ) THEN
                            err_out_cnt := err_out_cnt + 1;
                        END IF;
                        IF ( data_out /= unencoded_sig_delayed ) THEN
                            write( stdout_buf, string'( "Incorrect value decoded at time " ) );
                            write( stdout_buf, now );
                            writeline( output, stdout_buf );
                        END IF;
                    END IF;

                END LOOP;

            END PROCESS process_output;

END behavioral;


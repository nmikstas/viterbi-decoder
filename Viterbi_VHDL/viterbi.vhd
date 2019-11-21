--------------------------------------------------------------------------------
--
-- Title: Viterbi Decoder Algorithm
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
USE ieee.std_logic_signed.ALL;


ENTITY viterbi IS 
    PORT (
        clk              : IN  std_logic;
        rst              : IN  std_logic;
        data_in          : IN  std_logic_vector( 1 DOWNTO 0 );
        data_out         : OUT std_logic;
        
        --
        --ADDED STUFF HERE--------------------------------------------------------------------------
        --
        swindow0         : OUT std_logic_vector( 0 TO 3 );
        distance0        : OUT integer;
        distance1        : OUT integer;
        distance2        : OUT integer;
        distance3        : OUT integer;
        survivors0       : OUT std_logic_vector( 0 TO 3 )
    );
END viterbi;


ARCHITECTURE behavioral OF viterbi IS 

BEGIN 

    main_proc: PROCESS 

        CONSTANT window_length : integer := 16;

        SUBTYPE  survivor_elements IS std_logic_vector( 0 TO 3 );
        TYPE     survivor_window_type IS ARRAY ( integer RANGE <> ) OF survivor_elements;
        VARIABLE survivor_window       : survivor_window_type( window_length - 1 DOWNTO 0 );
        
        VARIABLE survivors             : survivor_elements;
        VARIABLE backtrack_survivors   : survivor_elements;

        TYPE     distance_array_type IS ARRAY ( 0 TO 3 ) OF integer RANGE 0 TO 3;
        VARIABLE distance              : distance_array_type;
        VARIABLE global_distance       : distance_array_type;

        VARIABLE data_in_v             : std_logic_vector( 1 DOWNTO 0 );

        TYPE     branch_distance_array_type IS ARRAY ( 0 TO 3 ) OF integer RANGE 0 TO 7;
        VARIABLE upper_branch_distance : branch_distance_array_type;
        VARIABLE lower_branch_distance : branch_distance_array_type;
        VARIABLE branch_distance       : branch_distance_array_type;
        VARIABLE minimum_branch        : integer RANGE 0 TO 7;

        SUBTYPE  state_type IS integer RANGE 0 TO 3;
        VARIABLE state                 : state_type;
        VARIABLE branch_direction      : std_logic;
    BEGIN

        data_out <= '0';

        --
        -- Initialize survivor memory
        --
        FOR i IN window_length - 1 DOWNTO 0 LOOP
            survivor_window( i ) := ( OTHERS => '0' );
        END LOOP;

        --
        -- Initialize global distances
        --
        FOR i IN 3 DOWNTO 1 LOOP
            global_distance( i ) := 2;
        END LOOP;
        global_distance( 0 ) := 0;

        main_loop: LOOP

            WAIT UNTIL ( clk'EVENT AND clk = '1' );
            EXIT main_loop WHEN ( rst = '1' );
 
            data_in_v := data_in;

            -- 
            -- Calculate distances (# of bits which are different)
            -- 
            CASE data_in_v IS
                WHEN "00" =>
                    distance( 0 ) := 0;
                    distance( 1 ) := 1;
                    distance( 2 ) := 1;
                    distance( 3 ) := 2;
                WHEN "01" =>
                    distance( 0 ) := 1;
                    distance( 1 ) := 0;
                    distance( 2 ) := 2;
                    distance( 3 ) := 1;
                WHEN "10" =>
                    distance( 0 ) := 1;
                    distance( 1 ) := 2;
                    distance( 2 ) := 0;
                    distance( 3 ) := 1;
                WHEN "11" =>
                    distance( 0 ) := 2;
                    distance( 1 ) := 1;
                    distance( 2 ) := 1;
                    distance( 3 ) := 0;
                WHEN OTHERS =>
                    NULL;
            END CASE;

            --
            -- Add-Compare-Select (ACS)
            --
            acs_loop: FOR i IN 0 TO 3 LOOP

                --
                -- Calculate distances for the upper and lower branches
                --
                CASE i IS

                    WHEN 0 => upper_branch_distance( i ) := distance( 0 ) + global_distance( 0 );  --   st0 === "00" (0) ==> st0
                              lower_branch_distance( i ) := distance( 3 ) + global_distance( 2 );  --   st2 === "11" (3) ==> st0

                    WHEN 1 => upper_branch_distance( i ) := distance( 3 ) + global_distance( 0 );  --   st0 === "11" (3) ==> st1
                              lower_branch_distance( i ) := distance( 0 ) + global_distance( 2 );  --   st2 === "00" (0) ==> st1

                    WHEN 2 => upper_branch_distance( i ) := distance( 1 ) + global_distance( 1 );  --   st1 === "01" (1) ==> st2
                              lower_branch_distance( i ) := distance( 2 ) + global_distance( 3 );  --   st3 === "10" (2) ==> st2

                    WHEN 3 => upper_branch_distance( i ) := distance( 2 ) + global_distance( 1 );  --   st1 === "10" (2) ==> st3
                              lower_branch_distance( i ) := distance( 1 ) + global_distance( 3 );  --   st3 === "01" (1) ==> st3

                END CASE;

                --
                -- Select the surviving branch and fill appropriate value into the survivor window 
                --
                IF ( upper_branch_distance( i ) <= lower_branch_distance( i ) ) THEN
                    branch_distance( i ) := upper_branch_distance( i );
                    survivors( i ) := '0';
                ELSE
                    branch_distance( i ) := lower_branch_distance( i );
                    survivors( i ) := '1';
                END IF;

            END LOOP;

            survivor_window( 0 ) := survivors;

            --
            -- Find the minimum branch distance and the ending state
            --
            minimum_branch := branch_distance( 0 );
            state := 0;

            find_minimum: FOR i IN 1 TO 3 LOOP
                IF ( branch_distance( i ) < minimum_branch ) THEN
                    minimum_branch := branch_distance( i );
                    state := i;
                END IF;
            END LOOP;

            --
            -- Subtract the minimum distance to avoid overflow
            --
            normalize: FOR i IN 0 TO 3 LOOP
                global_distance( i ) := branch_distance( i ) - minimum_branch;
            END LOOP;

            --
            -- Backtrack the survivor window from the most-likely state
            --
            backtrack: FOR i IN 0 TO window_length - 1 LOOP

                backtrack_survivors := survivor_window( i );
                branch_direction := backtrack_survivors( state );

                CASE state IS
                    WHEN 0 | 1 => IF ( branch_direction = '0' ) THEN
                                      state := 0;
                                  ELSE
                                      state := 2;
                                  END IF;
                    WHEN 2 | 3 => IF ( branch_direction = '0' ) THEN
                                      state := 1;
                                  ELSE
                                      state := 3;
                                  END IF;
                END CASE;

            END LOOP;

            --
            -- Shift the survivor window values
            --
            shift: FOR i IN window_length - 1 DOWNTO 1 LOOP
                survivor_window( i ) := survivor_window( i - 1 );
            END LOOP;

            --
            -- Generate output
            --
            data_out <= branch_direction;

            --
            --ADDED STUFF HERE----------------------------------------------------------------------
            --
            swindow0 <= survivor_window(0);
            distance0 <= distance(0);
            distance1 <= distance(1);
            distance2 <= distance(2);
            distance3 <= distance(3);
            survivors0 <= survivors;
            
        END LOOP main_loop;

    END PROCESS;

END behavioral;

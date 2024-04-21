This software is a simulation exercise designed to solve systems of linear equations using iterative methods. It provides two methods for solving these systems: Gauss-Seidel and Jacobi.

##Features
Solve systems of linear equations using Gauss-Seidel or Jacobi iterative methods.
Control the precision of the solution with a fixed number of bits.
Set a maximum number of iterations for the solver.
Output the solution to a text file, with the option to append or overwrite existing content.

##Usage
You can run the program from the command line with the following arguments:

-method: The iterative method to use. Use "g" for Gauss-Seidel or "j" for Jacobi.
-output: The name of the output file.
-max_iteration: The maximum number of iterations for the solver.
-bit: The number of bits used in fixed point.
Example:

This command will run the program with the Gauss-Seidel method, output the results to output.txt, limit the solver to 1000 iterations, and use 30 bits of precision.
python main.py -method g -output output_gaussian.txt -max_iteration 1000 -bit 30

##Requirements
Python 3.6 or later

##License
This software is released under the MIT License. See LICENSE for more information.
# Exercism Solutions

This repository contains [my solutions](https://exercism.org/profiles/AyomideA-S/solutions) to the tracks on [Exercism](https://exercism.org). I use these challenges to sharpen my proficiency in languages like Python, C, and R.

## 🚀 Progress

| Language | Progress | Key Concepts Covered |
| :--- | :--- | :--- |
| C | 1/84 | Functions |
| Python | 2/143 | Basics |
| R | 5/85 | Conditionals, Arithmetic |
| x86-64 Assembly | 1/114 | Basic Syntax |

## 🛠 Project Structure

Each folder is organized by language and then by exercise name:
`/[language]/[exercise-name]/`

## 📝 Learning Notes

I often document "Aha!" moments from these challenges in my personal PKM system. Significant breakthroughs regarding algorithms or language-specific syntax are mirrored here in the exercise directories.

### General Concepts

#### Cartesian Coordinates

Distance between two points ($x_1, y_1$) and ($x_2, y_2$) is calculated using the formula:

$$
d = \sqrt{(x_2 - x_1)^2 + (y_2 - y_1)^2}
$$

### R

#### Vectors

Vectors in R are sequences of data elements of the same basic type. They can be created using the `c()` function:

```r
my_vector <- c("name" = "value", "age" = "25", "city" = "New York")
print(my_vector)
# Output:
#     name   age        city
#  "value"  "25"  "New York"
names(my_vector)
# [1] "name"  "age"  "city"
my_vector["age"]
# [1] "25"
my_vector[1]
# [1] "value"
```

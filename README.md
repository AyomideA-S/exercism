# Exercism Solutions

This repository contains [my solutions](https://exercism.org/profiles/AyomideA-S/solutions) to the tracks on [Exercism](https://exercism.org). I use these challenges to sharpen my proficiency in languages like Python, C, and R.

## 🚀 Progress

| Language | Progress | Key Concepts Covered |
| :--- | :--- | :--- |
| C | 1/84 | Functions |
| Python | 2/143 | Basics |
| R | 17/85 | Conditionals, Arithmetic, Vectors, Lists, Binary, S3, ISODate |
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

#### Hamming Distance

The Hamming distance between two strings ($s_1$ and $s_2$) of equal length ($n$) is the number of positions at which the corresponding symbols are different. It is calculated by comparing each character in the strings and counting the differences.

$$
\text{Hamming Distance} = \sum_{i=1}^{n} (s_1[i] \neq s_2[i])
$$

### R

#### Mapping Functions

In R, the `Map()` function applies a specified function to corresponding elements of given vectors or lists. It returns a list of the results. For example:

```r
# Define a function to add two numbers
add <- function(x, y) {
  return(x + y)
}
# Use Map to apply the add function to two vectors
result <- Map(add, c(1, 2, 3), c(4, 5, 6))
print(result)
# Output: [[1]] 5 [[2]] 7 [[3]] 9

# Alternatively, we can also map operators directly
result <- Map(`!=`, c(1, 2, 3), c(1, 0, 3))
print(result)
# Output: [[1]] FALSE [[2]] TRUE [[3]] FALSE
# Summing up the TRUE values to get the count of equal elements
hamming_distance <- sum(unlist(result))
print(hamming_distance)  # Output: 1

# Using anonymous functions with Map
result <- Map(function(x, y) x * y, c(1, 2, 3), c(4, 5, 6))
print(result)
# Output: [[1]] 4 [[2]] 10 [[3]] 18
```

#### String Splitting

In R, the `strsplit()` function is used to split strings into substrings based on a specified delimiter. It returns a list of character vectors. For example:

```r
# Split a string by characters
result <- strsplit("Hello", "")
print(result)
# Output: [[1]] "H" "e" "l" "l" "o"
```

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

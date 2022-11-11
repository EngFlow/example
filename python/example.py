def fizzbuzz(i: int) -> str:
    if i % 3 == 0:
        if i % 5 == 0:
            return "FizzBuzz"
        else:
            return "Fizz"
    elif i % 5 == 0:
        return "Buzz"
    else:
        return str(i)

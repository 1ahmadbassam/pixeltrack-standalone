from collections import Set

fn main():
    var my_set = Set[Int](1, 2, 3)
    var iter = my_set.__iter__()
    var iter1 = iter
    var item = iter.__next__()  # Retrieves the next item from the set

    print(item)
    
    item = iter1.__next__()  # Retrieves the next item from the set

    print(item)

    item = iter.__next__()  # Retrieves the next item from the set

    print(item)
    
    item = iter1.__next__()  # Retrieves the next item from the set

    print(item)
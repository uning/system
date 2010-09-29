<?php
function print_counter_info($counter)
{
    if (is_resource($counter)) {
        printf("Counter's name is '%s' and is%s persistent. Its current value is %d.\n",
            counter_get_meta($counter, COUNTER_META_NAME),
            counter_get_meta($counter, COUNTER_META_IS_PERSISTENT) ? '' : ' not',
            counter_get_value($counter));
    } else {
      print "Not a valid counter!\n";
    }
}

if (($counter_one = counter_get_named("one")) === NULL) {
    $counter_one = counter_create("one", 0, COUNTER_FLAG_PERSIST);
}
counter_bump_value($counter_one, 2);
$counter_two = counter_create("two", 5);
$counter_three = counter_get_named("three");
$counter_four = counter_create("four", 2, COUNTER_FLAG_PERSIST | COUNTER_FLAG_SAVE | COUNTER_FLAG_NO_OVERWRITE);
counter_bump_value($counter_four, 1);

print_counter_info($counter_one);
print_counter_info($counter_two);
print_counter_info($counter_three);
print_counter_info($counter_four);
?> 


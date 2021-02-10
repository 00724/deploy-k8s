//if-else语句
buildType = "gradle"
if (buildType == "maven") {
    println("This is a maven project!")
} else if (buildType == 'gradle'){
    println("This is a gradle project!")
} else{
    println("Project buildType is error!")
}


//switch控制语句
buildType = "maven"
switch ("$buildType"){
    case "maven":
        println("This is a maven project!")
        break;
        ;;
    case "gradle":
        println("This is a gradle project!")
        break;
        ;;
    default:
        println("Project build error!")
        ;;
}

//for循环
fruits = ['apple','banana','orange']
for ( fruit in fruits){
    println("fruit is ${fruit}")
}

//带if-else的for循环
fruits = ['apple','banana','orange']
for ( fruit in fruits){
    if (fruit == 'apple'){
        println("fruit is ${fruit}")
    }else {
        println("fruit is ${fruit}")
    }

}


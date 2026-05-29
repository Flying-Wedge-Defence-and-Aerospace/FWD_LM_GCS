import QtQuick 2.3
import QtQuick.Controls 1.2
import QGroundControl.FactSystem 1.0
import QGroundControl.Controls 1.0

QGCToggleSwitch {
    property Fact fact: Fact { }
    property variant checkedValue: 1
    property variant uncheckedValue: 0

    // Keep UI synced with the Fact
    Binding on checked {
        value: fact ?
                   (fact.typeIsBool ?
                        (fact.value === false ? false : true) :
                        (fact.value === 0 ? false : true)) :
                   false
    }

    // Update Fact when user toggles
    onCheckedChanged: {
        if (fact)
            fact.value = checked ? checkedValue : uncheckedValue
    }
}



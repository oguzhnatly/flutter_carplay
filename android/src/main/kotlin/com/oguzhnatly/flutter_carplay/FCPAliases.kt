package com.oguzhnatly.flutter_carplay

import androidx.car.app.model.Action
import androidx.car.app.model.CarIcon
import androidx.car.app.model.GridItem
import androidx.car.app.model.GridTemplate
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.LongMessageTemplate
import androidx.car.app.model.MessageTemplate
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.SectionedItemList
import androidx.car.app.model.Template
import androidx.car.app.navigation.model.Destination
import androidx.car.app.navigation.model.NavigationTemplate
import androidx.car.app.navigation.model.Trip

typealias Bool = Boolean
typealias CGFloat = Double
typealias UIImage = CarIcon
typealias CPTemplate = Template
typealias CPListItem = Row
typealias CPListTemplate = ListTemplate
typealias CPListSection = SectionedItemList
typealias CPBarButton = Action
typealias CPMapButton = Action
typealias CPTextButton = Action
typealias CPAlertAction = Action
typealias CPGridTemplate = GridTemplate
typealias CPGridButton = GridItem
typealias CPActionSheetTemplate = LongMessageTemplate
typealias CPAlertTemplate = MessageTemplate
typealias CPInformationTemplate = PaneTemplate
typealias CPInformationItem = Row
typealias CPMapTemplate = NavigationTemplate
typealias CPRouteChoice = Destination
typealias CPTrip = Trip

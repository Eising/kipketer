$(function() {
    $.validator.addMethod('IP4Checker', function(value) {
        var ip = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$";
    return value.match(ip);
}, 'Invalid IP address');
});
$(function() {
    $.validator.addMethod('IP4NetChecker', function(value) {
        var net = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\/[0-9]+$";
        return value.match(net);
    }, 'Invalid IP network');
});
$(function() {
    $.validator.addMethod('zipcityChecker', function(value) {
        var zipcity = "^[0-9]{4}.*$";
        return value.match(zipcity);
    }, 'Invalid zipcode');
});
$(function() {
    $.validator.addMethod('InterfaceChecker', function(value) {
        var interface = "^(GigabitEthernet([0-9]+\/[0-9]+)|TenGigabitEthernet([0-9]+\/[0-9]+)|TenGigE([0-9]+\/[0-9]+\/[0-9]+\/[0-9]+)|Vlan|Bundle-Ether([0-9]+)|GigabitEthernet([0-9]+\/[0-9]+\/[0-9]+)|GigabitEthernet([0-9]+\/[0-9]+\/[0-9]+\/[0-9]+)|(?:xe|ge)-([0-9]+\/[0-9]+\/[0-9]+))$";
        return value.match(interface);
    }, "Invalid Interface");
});
$(function() {
    $.validator.addMethod('CridChecker', function(value) {
        
//        var crid = "^N[A-Z]{2}-[0-9]{6}$";
//        Insert your own logic here
        var crid = ".*";
        return value.match(crid);
    }, "Invalid CRID");
    
});
$(function() {
    $.validator.addClassRules({
        validatevlan: {
            range: [1, 4094]
        },
        validatenet: {
            IP4NetChecker: true
        },
        validateip: {
            IP4Checker: true
        },
        validateasn: {
            range: [1, 65535]
        },
        validatezipcity: {
            zipcityChecker: true
        },
        validateinterface: {
            InterfaceChecker: true
        },
        validatecrid: {
            CridChecker: true
        },
        validatespeed: {
            range: [1, 10000]
        }
    })
});

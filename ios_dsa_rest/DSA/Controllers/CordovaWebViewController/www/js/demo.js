        
    /* Controls handlers*/
    function onSyncButtonPressed(element)
    {		
        window.syncButtonPressed(null, null);
    }

    function loadTestPage(element)
    {
            var returnedObject = eval(result);
        window.getHTML5BundleFilePath(['Photography_Survey'], function(result) {
            cordova.logger.log("Cordova gotFileEntry "+returnedObject);
              window.location.href = returnedObject;
                                      
        });
    }
    
    function onResolveSuccess(fileEntry) {
        cordova.logger.log("onResolveSuccess Library");
        console.log(fileEntry.name);
    }

        
    // Called if something bad happens.
    //
    function fail(evt) {
        console.log(evt.target.error.code);
    }

    function getRecords(element)
    {
        window.getRecordsUsingQuery([document.getElementById('entity-input').value, document.getElementById('query-input').value], function(result) {

                                 //cordova.logger.log("Cordova Log test" + result);
             var returnedObject = eval(result);
             alert("Number of records: \r\n" + returnedObject.length);
                         
             document.getElementById('myjson').innerHTML=result;
             
             var jsondoc = eval('(' + result + ')');
             
             if(jsondoc.length > 0){
                 displayData(jsondoc);
             }
             else{
                 document.getElementById('mytable').innerHTML='No records found!';
             }
        });
    }
        
    function createTableRowContent(rowObject, data, cellType){
        var rowContent = document.createElement(cellType);
        var cell = document.createTextNode(data);
        rowContent.appendChild(cell);
        rowObject.appendChild(rowContent);
    }
    
    function createTableData(rowObject, data){
        createTableRowContent(rowObject, data, 'td');
    }
    
    function createTableHeader(rowObject, data){
        createTableRowContent(rowObject, data, 'th');
    }
    
    function displayData(jsonString){
        
        var table = document.createElement('table');
        table.border = "1";
        
        var thead = document.createElement('thead');
        table.appendChild(thead);
        
        var row = document.createElement('tr');
        
        createTableHeader(row, 'Name');
        createTableHeader(row, 'Id');
        createTableHeader(row, 'LastModifiedDate');;
        
        thead.appendChild(row);
        
        var tbody = document.createElement('tbody');
        table.appendChild(tbody);
        
        for(i=0; i<jsonString.length; i++){
            var row = document.createElement('tr');
            
            createTableData(row, jsonString[i].Name);
            createTableData(row, jsonString[i].Id);
            createTableData(row, jsonString[i].LastModifiedDate);
            
            tbody.appendChild(row);
        }
        
        document.getElementById('mytable').innerHTML = '';
        document.getElementById('mytable').appendChild(table);
    }

        //DSANavigationPlugin
        //works
        function openURLInsideCurrentView(element) {
            window.plugins.DSANavigationPlugin.openURL(document.getElementById('url-input').value,true,true, function(result) {

                                            console.log("Open URL success");
                                           }, function(result) {
                                            console.log("Error");
                                           });
        }
        
        //DSAContentPlugin
        //works
        function getCategoryArray(element) {
            
            window.plugins.DSAContentPlugin.getCategoryContentArray([document.getElementById('category-input').value], function(result) {
                                        var returnedObject = JSON.parse(result);
                                        console.log(returnedObject);
                                        console.log("Returned object[0].Name ======= " + returnedObject[0].Name);
                                        document.getElementById('category-text').value = JSON.stringify(returnedObject);
                                           
                                      }, function(result) {
                                        console.log("Error");
                                      });
        }

        //DSAContentPlugin
        //works
        function getCategory(element) {
            
            window.plugins.DSAContentPlugin.getCategoryContent([document.getElementById('category-input').value], function(result) {
                                        var returnedObject = JSON.parse(result);
                                        console.log("Returned object.Name ======= " + returnedObject.Name);
                                        document.getElementById('category-text').value = JSON.stringify(returnedObject);
                                           
                                      }, function(result) {
                                        console.log("Error");
                                      });
        }

        //DSANavigationPlugin
        //works
        function openCategorySample(element) {
            
            window.plugins.DSANavigationPlugin.openCategory([document.getElementById('openCategoryId-input').value], function(result) {
                                           var returnedObject = JSON.parse(result);
                                           console.log("Returned object[0].name ======= " + returnedObject[0].Name);
                                           document.getElementById('category-text').value = JSON.stringify(returnedObject[0]);
                                           
                                           }, function(result) {
                                           console.log("Error");
                                           });
        }
        
        //DSAContentPlugin
        //doesn't work
        function displayTrack(element) {
            window.plugins.DSAContentPlugin.displayContent("/Users/abilous/Library/Application Support/iPhone Simulator/6.0/Applications/5DF4FC8B-2CF8-4F51-8557-F87544622962/Library/Private Documents/Widget Pricing [068d0000000V9SXAA0].jpg", function(result) {
                                    console.log("displayTrack");
                                  }, function(result) {
                                    console.log("Error");
                                  });
        }
        
        //DSAContentPlugin
        //works
        function getContentPath(element) {
            
            window.plugins.DSAContentPlugin.getContentPathFromSFID(document.getElementById('categoryId-input').value, function(result) {
                                            console.log("getContentPathFromSFID " + result);
                                              document.getElementById('category-text').value = JSON.stringify(result);
                                          }, function(result) {
                                            console.log("Error");
                                          });
        }

        //DSAContactPlugin
        //works
        function getContactsList(element) {
            
            window.plugins.DSAContactPlugin.searchContact(document.getElementById('contactName-input').value, function(result) {
                                          
                                          console.log("getContactsList " + result);
                                          document.getElementById('category-text').value = JSON.stringify(result);
                                          }, function(result) {
                                          console.log("Error");
                                          });
        }
        
        //DSAContactPlugin
        //works
        function getCheckedInContact(element) {
            
            window.plugins.DSAContactPlugin.checkedInContact(function(result) {
                                            var returnedObject = JSON.parse(result);
                                              console.log("getCheckedInContact " + returnedObject[0].Name);
                                              document.getElementById('category-text').value = JSON.stringify(returnedObject[0]);
                                          }, function(result) {
                                              console.log("Error");
                                          });
        }

        //DSASynchronizedDataPlugin
        //works
        function getObjectsByIDs(element) {
            
            window.plugins.DSASynchronizedDataPlugin.get([document.getElementById('getObjectsByIDs-input').value], function(result) {
                                           var returnedObject = JSON.parse(result);
                                           console.log("Returned object[0].name ======= " + returnedObject[0].name);
                                           document.getElementById('category-text').value = JSON.stringify(returnedObject);
                                           
                                           }, function(result) {
                                           console.log("Error");
                                           });
        }
        
        //DSASynchronizedDataPlugin
        //works
        function searchObjects(element) {
            
            window.plugins.DSASynchronizedDataPlugin.search(document.getElementById('searchObjects-input').value, function(result) {
                                           var returnedObject = JSON.parse(result);
                                           console.log("Returned object[0].name ======= " + returnedObject[0].name);
                                           document.getElementById('category-text').value = JSON.stringify(returnedObject[0]);
                                           
                                           }, function(result) {
                                           console.log("Error");
                                           });
        }

        /**
        * DSAOAuthPlugin examples
        **/

        function OAuthSessionID(element) {
            window.plugins.DSAOAuthPlugin.getOAuthSessionID(function(result) {

                                     document.getElementById('category-text').value = result;

                                     }, function(result) {
                                     console.log("Error");
                                     });
        }
        
        function OAuthClientID(element) {
            
            window.plugins.DSAOAuthPlugin.getOAuthClientID(function(result) {
                                     document.getElementById('category-text').value = result;
                                     }, function(result) {
                                     console.log("Error");
                                     });
        }
        function refreshToken(element) {
            
            window.plugins.DSAOAuthPlugin.getRefreshToken(function(result) {
                                    document.getElementById('category-text').value = result;
                                    }, function(result) {
                                    console.log("Error");
                                    });
        }
        function UserAgentId(element) {
            
            window.plugins.DSAOAuthPlugin.getUserAgent(function(result) {
                                    document.getElementById('category-text').value = result;
                                    }, function(result) {
                                    console.log("Error");
                                    });
        }
        function instanceUrlString(element) {
            
            window.plugins.DSAOAuthPlugin.getInstanceUrl(function(result) {
                                    document.getElementById('category-text').value = result;
                                    }, function(result) {
                                    console.log("Error");
                                    });
        }
        function loginUrlString(element) {
            
            window.plugins.DSAOAuthPlugin.getLoginUrl(function(result) {
                                  document.getElementById('category-text').value = result;
                                  }, function(result) {
                                  console.log("Error");
                                  });
        }

        function OAuthParameters(element) {
            window.plugins.DSAOAuthPlugin.getOAuthParametersAndAppointmentDetails(function(result) {
                                                             document.getElementById('category-text').value = JSON.stringify(result);
                                  console.log(JSON.stringify(result))
                                  }, function(result) {
                                  console.log("Error");
                                 });
        }
/**
 * DSAAppointmentDetails examples
 **/

       function AppointmentDetails(element) {
            window.plugins.DSAAppointmentPlugin.checkedInAppointment(function(result) {
                                                                          document.getElementById('category-text').value = JSON.stringify(result);
                                                                          console.log(JSON.stringify(result))
                                                                          }, function(result) {
                                                                          console.log("Error");
                                                                          });
       }

/**
 * DSAQuotePlugin example
 **/

function createQuote(element){
    var json = {"Header":
        {"Contact":"To disscuss or accept your quotation please contact Ian Curtis on 07979 569822 or alternatively call us on 0800 009 4069",
            "QuoteDate":"November 27, 2012","QuoteNumber":"43923760","TranscationId":"1641767965","TotalPricePayable":"£4,079.31","Deposit":"£407.93","DepositReference":"81231231238","DepositPaidBy":"Cash","Balance":"£3,671.38","BalancePaidBy":"credit/debit card",
            "InstallationAddress":{"Name":"Mrs P JOHNSON","Street":"72 Lakers Rise, Banstead","PostalCode":"SM7 3JY","Telephone":"Tel:","Mobile":"Mob:"},
            "BillingAddress":{"Name":"Mrs P JOHNSON","Street":"72 Lakers Rise, Banstead","PostalCode":"SM7 3JY","Telephone":"Tel: 01737357610","Mobile":"Mob:"}},"CustomerNeeds":"During the visit today, you expressed the following needs and requirements:","Details":{"Description":"New Boiler Replacement","Products":[{"Description":"Boiler:","SubTotal":"£1,158.17",
                                                                                                                                                                                                                                                                                                                             "LineItems":[{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null}]},{"Description":"Standard Boiler Replacement:","SubTotal":"£1,982.43","LineItems":[{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"Horizontal flue terminal","Quantity":"(x 1)","Price":"£220.27","Total":null},{"Description":"Internal Condensate Connection","Quantity":"(x 1)","Price":"£103.39","Total":null},{"Description":"Connect Boiler Electrics and Test","Quantity":"(x 1)","Price":"£196.93","Total":null},{"Description":"Conventional to Combi Boiler Replacement Installation","Quantity":"(x 1)","Price":"£1,982.43","Total":null}]},{"Description":"Standard Boiler Replacement:","SubTotal":"£1,982.43","LineItems":[{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"Horizontal flue terminal","Quantity":"(x 1)","Price":"£220.27","Total":null},{"Description":"Internal Condensate Connection","Quantity":"(x 1)","Price":"£103.39","Total":null},{"Description":"Connect Boiler Electrics and Test","Quantity":"(x 1)","Price":"£196.93","Total":null},{"Description":"Conventional to Combi Boiler Replacement Installation","Quantity":"(x 1)","Price":"£1,982.43","Total":null}]},{"Description":"Standard Boiler Replacement:","SubTotal":"£1,982.43","LineItems":[{"Description":"1 Year Complimentary HomeCare 200","Quantity":"(x 1)","Price":"£0.00","Total":null},{"Description":"Horizontal flue terminal","Quantity":"(x 1)","Price":"£220.27","Total":null},{"Description":"Internal Condensate Connection","Quantity":"(x 1)","Price":"£103.39","Total":null},{"Description":"Connect Boiler Electrics and Test","Quantity":"(x 1)","Price":"£196.93","Total":null},{"Description":"Conventional to Combi Boiler Replacement Installation","Quantity":"(x 1)","Price":"£1,982.43","Total":null}]}]},
        "Footer":{"TotalGrossPrice":"£4,079.31","NetContractPrice":"£4,079.31"}}
    
    window.plugins.DSAQuotePlugin.create(json,function(result) {
                                                             document.getElementById('category-text').value = JSON.stringify(result);
                                                             console.log(JSON.stringify(result))
                                                             }, function(result) {
                                                             console.log("Error");
                                                             },1,1);
}

function deletePDF(element){
    var pdfPathString = "/Users/amisha.goyal/Library/Application Support/iPhone Simulator/6.0/Applications/6AFB8296-56A1-4D6E-A1C4-AED32D543374/Documents/Quote.pdf";
    window.plugins.DSAQuotePlugin.deletePDF(pdfPathString,function(result) {
                                         document.getElementById('category-text').value = JSON.stringify(result);
                                         console.log(JSON.stringify(result))
                                         }, function(result) {
                                         console.log("Error");
                                         });
}

function PDFSigned(element){
    alert('pdf signed');
}

function CPQAppLaunch(element){
    console.log("launch call back in js");
}
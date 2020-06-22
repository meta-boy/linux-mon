import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:linux_mon/utils/constants.dart';
import 'package:linux_mon/utils/dark_theme_script.dart';
import 'package:linux_mon/utils/data_parser.dart';
import 'package:flutter_echarts/flutter_echarts.dart';

class CpuPage extends StatefulWidget {
  CpuPage(this.stream);
  final Stream stream;

  @override
  _CpuPageState createState() => _CpuPageState();
}

class _CpuPageState extends State<CpuPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List _data = [
    {'name': DateTime.now().millisecondsSinceEpoch, 'value': 0}
  ];

  String jsonData;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double width = size.width;
    return StreamBuilder(
      stream: widget.stream,
      builder: (context, snapshot) {
        List cpuData;
        if (snapshot.hasData) {
          cpuData = dataParserFromJson(snapshot.data).cpuFreq;
          double clockspeed = cpuData[0];

          if (_data.length > 20) {
            _data.removeAt(0);
          }
          _data.add({
            'name': DateTime.now().millisecondsSinceEpoch,
            'value': clockspeed.round()
          });
          // print(jsonData);
          // print(_data);
        }
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: snapshot.hasData
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    // crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'CPU STATS',
                        style: kHeadingTextStyle,
                      ),
                      Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.0)),
                        padding: EdgeInsets.all(8.0),
                        child: Echarts(
                          extensions: [darkThemeScript],
                          theme: 'dark',
                          option: '''
                                 {
                      dataset: {
                        dimensions: ['name', 'value'],
                        source: ${jsonEncode(_data)},
                      },
                    grid: {
                        left: '15%',
                        right: '0%',
                        bottom: '16%',
                        top: '16%'
                      },

                          xAxis: {
                              type: 'time',
                              splitLine: {
                                  show: false
                              },
                              axisLine: {
                                  lineStyle: {
                                  color: '#ffffffa0'
                                }
                              }
                          },
                          yAxis: {
                              type: 'value',
                              boundaryGap: [0, '10%'],
                              splitLine: {
                                  show: false
                              },
                              name: 'MHz',
                                axisLine: {
                                  lineStyle: {
                                  color: 'rgba(255, 255, 255, 0.6)'
                                }
                              },


                          },
                          series: [{
                              type: 'line',
                              showSymbol: false,
                              hoverAnimation: false,
                              name: 'data',
                              type: 'line',
                              itemStyle: {
                                  color: '#FB4A4A'
                              },
                                areaStyle: {
                                  color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
                                      offset: 0,
                                      color: 'rgba(255, 158, 68, 0.2)'
                                  }, {
                                      offset: 1,
                                      color: 'rgba(255, 70, 131, 0.2)'
                                  }])
                              },
                             
                          }]
                    }

                  ''',
                        ),
                        width: size.width * 0.94,
                        height: size.height * 0.3,
                      ),
                      GridView.count(
                        padding:
                            EdgeInsets.symmetric(horizontal: width * 0.025),
                        shrinkWrap: true,
                        childAspectRatio: size.height / size.width * 0.75,
                        crossAxisCount: 2,
                        primary: false,
                        crossAxisSpacing: width * 0.025,
                        mainAxisSpacing: width * 0.03,
                        children: [
                          CpuStatsCard(
                            cardString: 'Current',
                            clockSpeed: cpuData[0],
                            cardImgPath: 'assets/current-cspeed.png',
                          ),
                          CpuStatsCard(
                              cardString: 'Max',
                              clockSpeed: cpuData[2],
                              cardImgPath: 'assets/max-cspeed.png'),
                          CpuStatsCard(
                              cardString: 'Min',
                              clockSpeed: cpuData[1],
                              cardImgPath: 'assets/min-cspeed.png')
                        ],
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Text('No data'),
                ),
        );
      },
    );
  }
}

class CpuStatsCard extends StatelessWidget {
  final double clockSpeed;
  final String cardString;
  final String cardImgPath;

  const CpuStatsCard(
      {Key key, this.clockSpeed, this.cardString, this.cardImgPath})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kCardBoxDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(cardImgPath, width: 35.0,),
          Text(
            '${clockSpeed.toStringAsFixed(0) ?? '--'} MHz',
            style: kCardHeadingTextStyle,
          ),
          Text('$cardString Clock Speed', style: kCardSubHeadingTextStyle)
        ],
      ),
    );
  }
}

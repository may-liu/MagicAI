import 'package:flutter/material.dart';
import 'package:magicai/entity/pair.dart';
import 'package:magicai/entity/system_settings.dart';
import 'package:magicai/modules/controls/adaptive_bottom_sheet.dart';
import 'package:magicai/services/system_manager.dart';

import 'model.dart';
import 'prompt_config_sheet.dart';

class PromptListView extends StatefulWidget {
  const PromptListView({super.key});

  @override
  State<PromptListView> createState() => _PromptListViewState();
}

class _PromptListViewState extends State<PromptListView> {
  final List<Pair<String, String>> _prompts = SystemConfig.instance.prompts;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final int _page = 0;
  final bool _isLoading = true;
  final bool _hasMore = true;
  int _selectedIndex = SystemManager.instance.currentPromptIndex();

  Future<void> _loadMoreItems() async {}

  void _addItem() {
    showConfigBottomSheet(
      context,
      PromptConfigSheet(
        onPromptSave: (config) {
          SystemConfig.instance.prompts.add(config);
          SystemManager.instance.saveSystemConfig();
          final newIndex = _prompts.length;

          setState(() {
            _listKey.currentState?.insertItem(
              newIndex - 1,
              duration: const Duration(milliseconds: 150),
            );
            if (newIndex == 1) {
              _handleItemSelected(newIndex - 1);
              // Navigator.pop(context);
            }
          });
        },
      ),
    );
  }

  void _onModifiedItem(int index) {
    showConfigBottomSheet(
      context,
      PromptConfigSheet(
        onPromptSave: (config) {
          setState(() {
            SystemConfig.instance.prompts[index] = config;
            // SystemConfig.instance.prompts.add(config);
            SystemManager.instance.saveSystemConfig();
          });
        },
        promptConfig: _prompts[index],
      ),
    );
  }

  void _removeItem(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('确认删除'),
            content: const Text('确定要删除此聊天记录吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performRemove(index);
                },
                child: const Text('删除'),
              ),
            ],
          ),
    );
  }

  void _performRemove(int index) {
    if (index >= _prompts.length) return;

    final removedItem = _prompts.removeAt(index);

    setState(() {
      if (_selectedIndex == index) {
        _selectedIndex = -1;
      } else if (_selectedIndex > index) {
        _selectedIndex--;
      }
    });

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildRemovingItem(removedItem, animation),
      duration: const Duration(milliseconds: 300),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除 "$removedItem"'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            _prompts.insert(index, removedItem);
            if (_selectedIndex >= index) _selectedIndex++;
            _listKey.currentState?.insertItem(index);
          },
        ),
      ),
    );
  }

  Widget _buildRemovingItem(
    Pair<String, String> item,
    Animation<double> animation,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ListTile(
          title: Text(item.first),
          subtitle: const Text('Last message...'),
        ),
      ),
    );
  }

  void _handleItemSelected(int index) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? -1 : index;
      SystemManager.instance.doSelectPrompt(index);
      Navigator.pop(context);
    });
  }

  Widget _buildModelConfigList() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ModelListView(
            listKey: _listKey,
            items: _prompts,
            hasMore: _hasMore,
            selectedIndex: _selectedIndex,
            onItemModified: _onModifiedItem,
            onItemRemoved: _removeItem,
            onLoadMore: _loadMoreItems,
            onItemSelected: _handleItemSelected,
            getTitleName: (list, index) => _prompts[index].first,
            getDescription:
                (list, index) =>
                    _prompts[index].second.length > 200
                        ? _prompts[index].second.substring(0, 200)
                        : _prompts[index].second,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // final size = MediaQuery.of(context).size;
    // final isDesktop = size.width > 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildModelConfigList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
